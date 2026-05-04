import * as functions from "firebase-functions/v1";
import { Timestamp } from "firebase-admin/firestore";

import { requireAppCheck } from "./shared/app-check";
import { logSecurityAudit } from "./shared/audit";
import { requireAdminAccessWithDb } from "./shared/admin-auth";
import { db } from "./shared/firestore-db";
import {
  ADMIN_WALLET_NOTIFICATION_PREF_FIELD,
  WALLET_EXPIRY_REMINDER_PREF_FIELD,
  WALLET_NOTIFICATION_PREF_FIELD,
} from "./shared/wallet-notification-preferences";

const walletConfigUtils = require("../src/wallet_config_utils.js") as {
  REQUIRED_PRICING_KEYS: string[];
  validateWalletPricingConfig: (
    pricing: Record<string, unknown>,
    options?: {
      allowNonPositive?: boolean;
      allowZeroOnly?: boolean;
    },
  ) => {
    valid: boolean;
    issues: Array<{
      code: string;
      field: string;
      message: string;
    }>;
    normalizedPricing: Record<string, unknown>;
  };
  formatIssues: (
    issues: Array<{
      code: string;
      field: string;
      message: string;
    }>,
  ) => string;
};

export const isCurrentUserAdmin = functions.https.onCall(async (_data, context) => {
  requireAppCheck(context);
  const { uid, source } = await requireAdminAccessWithDb(context, db);
  return { isAdmin: true, uid, authSource: source };
});

export const verifyWalletOperationalReadiness = functions.https.onCall(async (_data, context) => {
  requireAppCheck(context);
  const { uid, source } = await requireAdminAccessWithDb(context, db);
  const now = Timestamp.now();

  const [pricingDoc, reportsSample, walletSample, reminderEventsSample] = await Promise.all([
    db.collection("wallet_feature_pricing").doc("default").get(),
    db.collection("merchant_wallet_reports").limit(1).get(),
    db.collection("merchant_wallets").limit(1).get(),
    db.collection("wallet_notification_events")
      .where("type", "in", ["wallet_story_promotion_expiring", "wallet_offer_pin_expiring"])
      .limit(2)
      .get(),
  ]);

  const pricingData = pricingDoc.data() ?? {};
  const pricingValidation = walletConfigUtils.validateWalletPricingConfig(pricingData);
  const pricingStatus = pricingDoc.exists && pricingValidation.valid ? "PASS" : "FAIL";
  const pricingIssues = pricingValidation.valid
    ? []
    : pricingValidation.issues.map((issue) => issue.message);

  const readModelsStatus = !reportsSample.empty ? "PASS" : "WARN";
  const walletDefaultsStatus = !walletSample.empty ? "PASS" : "WARN";
  const notificationsStatus = !reminderEventsSample.empty ? "PASS" : "WARN";
  const readinessFailures: string[] = [];
  const readinessWarnings: string[] = [];
  if (pricingStatus !== "PASS") readinessFailures.push("pricing");
  if (readModelsStatus !== "PASS") readinessWarnings.push("read_models");
  if (walletDefaultsStatus !== "PASS") readinessWarnings.push("wallet_defaults");
  if (notificationsStatus !== "PASS") readinessWarnings.push("notifications");
  const overallStatus = readinessFailures.length > 0
    ? "FAIL"
    : readinessWarnings.length > 0
      ? "WARN"
      : "PASS";

  const diagnostics = {
    checkedAt: now.toMillis(),
    checkedByUid: uid,
    authSource: source,
    pricing: {
      status: pricingStatus,
      exists: pricingDoc.exists,
      requiredKeys: walletConfigUtils.REQUIRED_PRICING_KEYS,
      issues: pricingIssues,
    },
    readModels: {
      status: readModelsStatus,
      walletReportsCollectionReachable: true,
      hasAnyWalletReport: !reportsSample.empty,
    },
    maintenanceAssumptions: {
      lifecycleScheduleExpected: true,
      expiryReminderScheduleExpected: true,
    },
    notifications: {
      status: notificationsStatus,
      preferenceFieldsExpected: [
        WALLET_NOTIFICATION_PREF_FIELD,
        WALLET_EXPIRY_REMINDER_PREF_FIELD,
        ADMIN_WALLET_NOTIFICATION_PREF_FIELD,
      ],
      hasAnyExpiryReminderEvent: !reminderEventsSample.empty,
    },
    walletDefaults: {
      status: walletDefaultsStatus,
      hasAnyWalletDoc: !walletSample.empty,
      lowBalanceThresholdDefaultExpected: 10,
    },
    failureChecks: readinessFailures,
    warningChecks: readinessWarnings,
    overallStatus,
  };

  if (diagnostics.overallStatus === "FAIL") {
    logSecurityAudit("wallet_operational_readiness_failed", {
      checkedByUid: uid,
      authSource: source,
      pricingExists: pricingDoc.exists,
      pricingIssues: walletConfigUtils.formatIssues(pricingValidation.issues),
      failureChecks: readinessFailures,
      timestamp: now.toMillis(),
    });
  } else if (diagnostics.overallStatus === "WARN") {
    logSecurityAudit("wallet_operational_readiness_warned", {
      checkedByUid: uid,
      authSource: source,
      warningChecks: readinessWarnings,
      timestamp: now.toMillis(),
    });
  } else {
    logSecurityAudit("wallet_operational_readiness_passed", {
      checkedByUid: uid,
      authSource: source,
      timestamp: now.toMillis(),
    });
  }

  return diagnostics;
});
