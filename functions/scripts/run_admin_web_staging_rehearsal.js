#!/usr/bin/env node
/* eslint-disable no-console */

const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

function parseArgs(argv) {
  const args = {};
  for (const token of argv) {
    if (!token.startsWith("--")) continue;
    const [rawKey, ...valueParts] = token.slice(2).split("=");
    if (!rawKey) continue;
    args[rawKey.trim()] = valueParts.length > 0 ? valueParts.join("=").trim() : true;
  }
  return args;
}

function resolveProjectId(rootDir) {
  const direct = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || process.env.GOOGLE_CLOUD_PROJECT;
  if (typeof direct === "string" && direct.trim().length > 0) {
    return direct.trim();
  }

  const firebasercPath = path.join(rootDir, ".firebaserc");
  if (!fs.existsSync(firebasercPath)) {
    throw new Error("Missing .firebaserc and no GCLOUD_PROJECT provided.");
  }

  const firebaserc = JSON.parse(fs.readFileSync(firebasercPath, "utf8"));
  const projectId = firebaserc?.projects?.default;
  if (typeof projectId !== "string" || projectId.trim().length === 0) {
    throw new Error("Unable to resolve project id from .firebaserc.");
  }
  return projectId.trim();
}

function resolveServiceAccountPath(rootDir) {
  const envPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (typeof envPath === "string" && envPath.trim().length > 0 && fs.existsSync(envPath.trim())) {
    return envPath.trim();
  }

  const candidates = [
    path.join(rootDir, "service-account-key.json"),
    path.join(path.dirname(rootDir), "scripts", "serviceAccountKey.json"),
  ];
  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }

  throw new Error(
    "Missing service-account key. Set GOOGLE_APPLICATION_CREDENTIALS or place service-account-key.json under wain_app/.",
  );
}

function prepareAdminEnvironment(rootDir, projectId) {
  const serviceAccountPath = resolveServiceAccountPath(rootDir);
  const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, "utf8"));
  process.env.GOOGLE_APPLICATION_CREDENTIALS = serviceAccountPath;
  process.env.GCLOUD_PROJECT = projectId;
  return {
    serviceAccountPath,
    serviceAccountEmail: serviceAccount.client_email || null,
  };
}

function tsFromNow(offsetMs = 0) {
  return admin.firestore.Timestamp.fromMillis(Date.now() + offsetMs);
}

function callableContext(uid, token = {}) {
  return {
    auth: {
      uid,
      token,
    },
    app: {
      appId: "admin-web-release-runner",
      token: "staging-rehearsal",
    },
  };
}

function normalizeError(error) {
  return {
    code: error && error.code ? String(error.code) : null,
    message: error && error.message ? String(error.message) : String(error),
  };
}

async function expectFailure(action, { code = null, messageIncludes = null } = {}) {
  try {
    await action();
    return {
      passed: false,
      error: {
        code: null,
        message: "Expected failure but call succeeded",
      },
    };
  } catch (error) {
    const normalized = normalizeError(error);
    const codePass = code ? normalized.code === code : true;
    const messagePass = messageIncludes
      ? normalized.message.includes(String(messageIncludes))
      : true;
    return {
      passed: codePass && messagePass,
      error: normalized,
    };
  }
}

function extractPricing(data) {
  const row = data || {};
  return {
    story_promote_1d: Number(row.story_promote_1d),
    story_promote_3d: Number(row.story_promote_3d),
    story_promote_7d: Number(row.story_promote_7d),
    offer_pin_1d: Number(row.offer_pin_1d),
    offer_pin_3d: Number(row.offer_pin_3d),
    offer_pin_7d: Number(row.offer_pin_7d),
    currency: typeof row.currency === "string" && row.currency.trim().length > 0
      ? row.currency.trim()
      : "ILS",
  };
}

function clonePricing(pricing) {
  return {
    story_promote_1d: pricing.story_promote_1d,
    story_promote_3d: pricing.story_promote_3d,
    story_promote_7d: pricing.story_promote_7d,
    offer_pin_1d: pricing.offer_pin_1d,
    offer_pin_3d: pricing.offer_pin_3d,
    offer_pin_7d: pricing.offer_pin_7d,
    currency: pricing.currency,
  };
}

function incrementPricing(pricing) {
  return {
    ...clonePricing(pricing),
    story_promote_1d: pricing.story_promote_1d + 1,
    offer_pin_1d: pricing.offer_pin_1d + 1,
  };
}

function samePricing(left, right) {
  return JSON.stringify(clonePricing(left)) === JSON.stringify(clonePricing(right));
}

async function seedVenue(db, venueId) {
  await db.collection("venues").doc(venueId).set({
    name_ar: `Phase7 ${venueId}`,
    city_ar: "Ramallah",
    category: "staging",
    is_active: true,
    created_at: tsFromNow(-60_000),
    updated_at: tsFromNow(-5_000),
  }, { merge: true });
}

async function seedAdmin(db, uid, role) {
  await db.collection("admins").doc(uid).set({
    active: true,
    role,
    created_at: tsFromNow(-60_000),
    updated_at: tsFromNow(-5_000),
  }, { merge: true });
}

async function seedOffer(db, { offerId, venueId }) {
  await db.collection("offers").doc(offerId).set({
    venue_id: venueId,
    title: `Offer ${offerId}`,
    title_ar: `Offer ${offerId}`,
    image_url: `https://cdn.example.com/${offerId}.jpg`,
    is_active: true,
    admin_state: "pending",
    created_at: tsFromNow(-30_000),
    updated_at: tsFromNow(-10_000),
    start_at: tsFromNow(-30_000),
    end_at: tsFromNow(86_400_000),
  }, { merge: true });
}

async function seedStory(db, { storyId, venueId }) {
  await db.collection("stories").doc(storyId).set({
    venue_id: venueId,
    caption: `Story ${storyId}`,
    image_url: `https://cdn.example.com/${storyId}.jpg`,
    is_active: true,
    admin_state: "pending",
    created_at: tsFromNow(-30_000),
    updated_at: tsFromNow(-10_000),
    expires_at: tsFromNow(86_400_000),
  }, { merge: true });
}

async function seedReview(db, { venueId, reviewId }) {
  await db.collection("venues").doc(venueId).collection("reviews").doc(reviewId).set({
    author_name: "Stage Guest",
    rating: 4,
    comment: `Review ${reviewId}`,
    status: "published",
    moderation_state: "published",
    created_at: tsFromNow(-20_000),
    updated_at: tsFromNow(-10_000),
  }, { merge: true });
}

async function seedTopUpProof(db, { requestId, venueId, mediaUrl }) {
  await db.collection("merchant_topup_requests").doc(requestId).set({
    venue_id: venueId,
    requested_by_uid: `merchant_${venueId}`,
    amount: 55,
    currency: "ILS",
    status: "pending",
    proof_image_url: mediaUrl,
    created_at: tsFromNow(-20_000),
    updated_at: tsFromNow(-10_000),
  }, { merge: true });
}

async function setMediaReferenceHealth(db, status) {
  await db.collection("media_reference_index").doc("health").set({
    current_health_status: status,
    last_successful_build_at: tsFromNow(status === "healthy" ? -5_000 : -900_000),
    updated_at: tsFromNow(-1_000),
  }, { merge: true });
}

async function findHistoryDocByLiveVersion(db, liveVersion) {
  if (!Number.isInteger(liveVersion) || liveVersion <= 0) {
    return null;
  }
  const snap = await db.collection("config_publish_history")
    .where("live_version", "==", liveVersion)
    .limit(1)
    .get();
  if (snap.empty) {
    return null;
  }
  return {
    id: snap.docs[0].id,
    data: snap.docs[0].data() || {},
  };
}

async function writeJson(outputPath, payload) {
  await fs.promises.mkdir(path.dirname(outputPath), { recursive: true });
  await fs.promises.writeFile(outputPath, `${JSON.stringify(payload, null, 2)}\n`, "utf8");
}

async function run() {
  const args = parseArgs(process.argv.slice(2));
  const rootDir = path.resolve(__dirname, "../..");
  const outputPath = args.output
    ? path.resolve(process.cwd(), String(args.output))
    : path.join(rootDir, "docs", "release", "admin_web_console_staging_evidence_log.json");

  const projectId = resolveProjectId(rootDir);
  const credentialMeta = prepareAdminEnvironment(rootDir, projectId);

  const {
    getAdminConfigGovernanceBundle,
    configUpsertDraft,
    configReviewDraft,
    configPublishDraft,
    configRollbackVersion,
    listOffersForAdmin,
    listStoriesForAdmin,
    contentModerateOffer,
    contentModerateStory,
    listVenueReviewsForAdmin,
    moderateVenueReviewForAdmin,
    getAdminMediaInventoryReadBundle,
    mediaSoftDeleteAsset,
    mediaQuarantineAsset,
    mediaReferenceCheckAsset,
    mediaPurgeAsset,
  } = require("../lib/index.js");
  const db = admin.firestore();

  const runId = `phase7_${Date.now()}`;
  const venueId = `venue_${runId}`;
  const offerId = `offer_${runId}`;
  const storyId = `story_${runId}`;
  const reviewId = `review_${runId}`;
  const mediaRequestId = `media_req_${runId}`;
  const mediaUrl = `venues/${venueId}/wallet_topups/${runId}.jpg`;

  const financeReviewerCtx = callableContext("finance-reviewer-phase7", {
    admin: true,
    role: "finance_admin",
    finance_admin: true,
  });
  const financePublisherCtx = callableContext("finance-publisher-phase7", {
    admin: true,
    role: "finance_admin",
    finance_admin: true,
  });
  const financeRollbackCtx = callableContext("finance-rollback-phase7", {
    admin: true,
    role: "finance_admin",
    finance_admin: true,
  });
  const contentAdminCtx = callableContext("content-admin-phase7", {
    admin: true,
    role: "content_admin",
    content_admin: true,
  });
  const superAdminCtx = callableContext("super-admin-phase7", {
    admin: true,
    role: "super_admin",
    super_admin: true,
  });
  const financeDeniedCtx = callableContext("finance-denied-phase7", {
    admin: true,
    role: "finance_admin",
    finance_admin: true,
  });
  const contentDeniedCtx = callableContext("content-denied-phase7", {
    admin: true,
    role: "content_admin",
    content_admin: true,
  });
  const plainCtx = callableContext("plain-user-phase7", {});

  const evidence = {
    runId,
    projectId,
    startedAt: new Date().toISOString(),
    operatorMode: "script-driven staging rehearsal with local callable modules against live Firestore",
    authMode: "service-account cert from repo-local key",
    serviceAccountPath: credentialMeta.serviceAccountPath,
    serviceAccountEmail: credentialMeta.serviceAccountEmail,
    transportCoverage: {
      callableLogicLiveProject: true,
      deployedBrowserHttpTransport: false,
      note: "HTTP callable transport with auth/app-check tokens is not exercised by this rehearsal.",
    },
    seed: {
      venueId,
      offerId,
      storyId,
      reviewId,
      mediaRequestId,
      mediaUrl,
    },
    config: {},
    content: {},
    reviews: {},
    media: {},
    decision: {},
    notes: [],
  };

  await seedVenue(db, venueId);
  await seedAdmin(db, "finance-reviewer-phase7", "finance_admin");
  await seedAdmin(db, "finance-publisher-phase7", "finance_admin");
  await seedAdmin(db, "finance-rollback-phase7", "finance_admin");
  await seedAdmin(db, "content-admin-phase7", "content_admin");
  await seedAdmin(db, "super-admin-phase7", "super_admin");
  await seedOffer(db, { offerId, venueId });
  await seedStory(db, { storyId, venueId });
  await seedReview(db, { venueId, reviewId });
  await seedTopUpProof(db, { requestId: mediaRequestId, venueId, mediaUrl });
  await setMediaReferenceHealth(db, "healthy");

  const liveConfigRef = db.collection("wallet_feature_pricing").doc("default");
  const initialLiveDoc = await liveConfigRef.get();
  if (!initialLiveDoc.exists) {
    throw new Error("wallet_feature_pricing/default is missing; cannot run config rehearsal safely.");
  }

  const initialPricing = extractPricing(initialLiveDoc.data());
  const initialLiveVersion = Number.isInteger(initialLiveDoc.data().live_version)
    ? Number(initialLiveDoc.data().live_version)
    : 0;
  const initialHistoryDoc = await findHistoryDocByLiveVersion(db, initialLiveVersion);
  const initialBundle = await getAdminConfigGovernanceBundle.run({ historyLimit: 10 }, financeReviewerCtx);

  evidence.config.initial = {
    liveVersion: initialLiveVersion,
    historyForCurrentVersionExists: Boolean(initialHistoryDoc),
    draftStatus: initialBundle.draft.status,
    draftVersion: initialBundle.draft.draftVersion,
    pricing: clonePricing(initialPricing),
  };

  let rollbackTargetVersion = initialLiveVersion;
  let baselinePublish = null;
  let workingBaselinePricing = clonePricing(initialPricing);
  let currentDraftStatus = initialBundle.draft.status;
  let currentDraftVersion = initialBundle.draft.draftVersion;

  if (!initialHistoryDoc) {
    const baselineDraft = await configUpsertDraft.run({
      commandId: `${runId}_config_draft_baseline`,
      correlationId: `${runId}_config_draft_baseline`,
      reason: "phase7_baseline_publish",
      pricing: clonePricing(initialPricing),
      expectedState: {
        draft_status: currentDraftStatus,
        ...(currentDraftVersion > 0 ? { draft_version: currentDraftVersion } : {}),
      },
    }, financeReviewerCtx);

    const baselineReview = await configReviewDraft.run({
      commandId: `${runId}_config_review_baseline`,
      correlationId: `${runId}_config_review_baseline`,
      reason: "phase7_baseline_review",
      note: "Baseline draft reviewed for staging rehearsal",
      expectedState: {
        draft_status: "drafted",
        draft_version: baselineDraft.draftVersion,
      },
    }, financeReviewerCtx);

    const deniedPublish = await expectFailure(
      () => configPublishDraft.run({
        commandId: `${runId}_config_publish_denied`,
        correlationId: `${runId}_config_publish_denied`,
        reason: "phase7_denied_role_check",
        expectedState: {
          draft_status: "reviewed",
          draft_version: baselineReview.draftVersion,
          target_live_version: initialLiveVersion,
        },
      }, contentDeniedCtx),
      { code: "permission-denied", messageIncludes: "config_role_not_authorized" },
    );

    baselinePublish = await configPublishDraft.run({
      commandId: `${runId}_config_publish_baseline`,
      correlationId: `${runId}_config_publish_baseline`,
      reason: "phase7_publish_current_baseline",
      note: "Publish current pricing as governed baseline",
      expectedState: {
        draft_status: "reviewed",
        draft_version: baselineReview.draftVersion,
        target_live_version: initialLiveVersion,
      },
    }, financePublisherCtx);

    rollbackTargetVersion = baselinePublish.liveVersion;
    currentDraftStatus = "published";
    currentDraftVersion = baselinePublish.draftVersion;
    evidence.config.baselinePublish = {
      deniedPublishByContentRole: deniedPublish,
      result: baselinePublish,
    };
  }

  const temporaryPricing = incrementPricing(workingBaselinePricing);
  const tempDraft = await configUpsertDraft.run({
    commandId: `${runId}_config_draft_temp`,
    correlationId: `${runId}_config_draft_temp`,
    reason: "phase7_temp_publish",
    pricing: temporaryPricing,
    expectedState: {
      draft_status: currentDraftStatus,
      ...(currentDraftVersion > 0 ? { draft_version: currentDraftVersion } : {}),
    },
  }, financeReviewerCtx);

  const tempReview = await configReviewDraft.run({
    commandId: `${runId}_config_review_temp`,
    correlationId: `${runId}_config_review_temp`,
    reason: "phase7_temp_review",
    note: "Temporary drift for rollback rehearsal",
    expectedState: {
      draft_status: "drafted",
      draft_version: tempDraft.draftVersion,
    },
  }, financeReviewerCtx);

  const distinctReviewerConflict = await expectFailure(
    () => configPublishDraft.run({
      commandId: `${runId}_config_publish_same_actor`,
      correlationId: `${runId}_config_publish_same_actor`,
      reason: "phase7_same_actor_block",
      expectedState: {
        draft_status: "reviewed",
        draft_version: tempReview.draftVersion,
        target_live_version: rollbackTargetVersion,
      },
    }, financeReviewerCtx),
    {
      code: "permission-denied",
      messageIncludes: "distinct_reviewer",
    },
  );

  const tempPublish = await configPublishDraft.run({
    commandId: `${runId}_config_publish_temp`,
    correlationId: `${runId}_config_publish_temp`,
    reason: "phase7_temp_publish_apply",
    note: "Apply temporary pricing drift",
    expectedState: {
      draft_status: "reviewed",
      draft_version: tempReview.draftVersion,
      target_live_version: rollbackTargetVersion,
    },
  }, financePublisherCtx);

  const rollbackResult = await configRollbackVersion.run({
    commandId: `${runId}_config_rollback`,
    correlationId: `${runId}_config_rollback`,
    reason: "phase7_restore_baseline",
    rollbackToVersion: rollbackTargetVersion,
    expectedState: {
      current_live_version: tempPublish.liveVersion,
    },
  }, financeRollbackCtx);

  const finalLiveDoc = await liveConfigRef.get();
  const finalPricing = extractPricing(finalLiveDoc.data());
  evidence.config.rehearsal = {
    temporaryPricing,
    distinctReviewerConflict,
    tempPublish,
    rollbackResult,
    finalLiveVersion: finalLiveDoc.data().live_version ?? null,
    pricingRestoredToBaseline: samePricing(finalPricing, workingBaselinePricing),
  };

  const offersList = await listOffersForAdmin.run({
    venueId,
    statuses: ["pending"],
    limit: 10,
    correlationId: `${runId}_offers_list`,
  }, contentAdminCtx);
  const storiesList = await listStoriesForAdmin.run({
    venueId,
    statuses: ["pending"],
    limit: 10,
    correlationId: `${runId}_stories_list`,
  }, contentAdminCtx);
  const offerApprove = await contentModerateOffer.run({
    offerId,
    venueId,
    action: "approve",
    reason: "quality_standard",
    commandId: `${runId}_offer_approve`,
    correlationId: `${runId}_offer_approve`,
    expectedState: {
      admin_state: "pending",
    },
  }, contentAdminCtx);
  const contentDenied = await expectFailure(
    () => contentModerateStory.run({
      storyId,
      venueId,
      action: "approve",
      reason: "quality_standard",
      commandId: `${runId}_story_denied`,
      expectedState: {
        admin_state: "pending",
      },
    }, financeDeniedCtx),
    {
      code: "permission-denied",
      messageIncludes: "content_role_not_authorized",
    },
  );
  const storyFlag = await contentModerateStory.run({
    storyId,
    venueId,
    action: "flag",
    reason: "unexpected_reason_value",
    commandId: `${runId}_story_flag`,
    correlationId: `${runId}_story_flag`,
    expectedState: {
      admin_state: "pending",
    },
  }, contentAdminCtx);
  evidence.content = {
    offersListCount: offersList.items.length,
    storiesListCount: storiesList.items.length,
    offerApprove,
    storyFlag,
    deniedByFinanceRole: contentDenied,
  };

  const reviewsList = await listVenueReviewsForAdmin.run({
    venueId,
    statuses: ["published"],
    limit: 10,
    correlationId: `${runId}_reviews_list`,
  }, contentAdminCtx);
  const reviewHide = await moderateVenueReviewForAdmin.run({
    action: "review_hide",
    venueId,
    reviewId,
    sourcePath: `venues/${venueId}/reviews/${reviewId}`,
    commandId: `${runId}_review_hide`,
    correlationId: `${runId}_review_hide`,
    reason: "privacy_request",
    expectedState: {
      moderation_state: "published",
    },
  }, contentAdminCtx);
  const reviewDenied = await expectFailure(
    () => listVenueReviewsForAdmin.run(
      { venueId, limit: 10 },
      financeDeniedCtx,
    ),
    {
      code: "permission-denied",
      messageIncludes: "review_moderation_role_not_authorized",
    },
  );
  const reviewConflict = await expectFailure(
    () => moderateVenueReviewForAdmin.run({
      action: "review_publish",
      venueId,
      reviewId,
      sourcePath: `venues/${venueId}/reviews/${reviewId}`,
      commandId: `${runId}_review_conflict`,
      correlationId: `${runId}_review_conflict`,
      reason: "manual_review",
      expectedState: {
        moderation_state: "published",
      },
    }, contentAdminCtx),
    {
      code: "failed-precondition",
      messageIncludes: "review_moderation_expected_state_conflict",
    },
  );
  evidence.reviews = {
    listCount: reviewsList.items.length,
    hide: reviewHide,
    deniedByFinanceRole: reviewDenied,
    expectedStateConflict: reviewConflict,
  };

  const mediaRead = await getAdminMediaInventoryReadBundle.run({
    proofLimit: 10,
    venuePhotoLimit: 10,
    offerImageLimit: 10,
    storyImageLimit: 10,
    correlationId: `${runId}_media_read`,
  }, superAdminCtx);
  const mediaReferenceCheck = await mediaReferenceCheckAsset.run({
    targetType: "topup_proof",
    targetId: mediaRequestId,
    sourceCollection: "merchant_topup_requests",
    sourceDocumentId: mediaRequestId,
    mediaUrl,
    commandId: `${runId}_media_ref_check`,
    correlationId: `${runId}_media_ref_check`,
    reason: "phase7_reference_check",
  }, contentAdminCtx);
  const mediaSoftDelete = await mediaSoftDeleteAsset.run({
    targetType: "topup_proof",
    targetId: mediaRequestId,
    sourceCollection: "merchant_topup_requests",
    sourceDocumentId: mediaRequestId,
    mediaUrl,
    commandId: `${runId}_media_soft_delete`,
    correlationId: `${runId}_media_soft_delete`,
    reason: "phase7_soft_delete_probe",
    expectedState: {
      media_state: "active",
    },
  }, contentAdminCtx);
  const mediaQuarantine = await mediaQuarantineAsset.run({
    targetType: "topup_proof",
    targetId: mediaRequestId,
    sourceCollection: "merchant_topup_requests",
    sourceDocumentId: mediaRequestId,
    mediaUrl,
    commandId: `${runId}_media_quarantine`,
    correlationId: `${runId}_media_quarantine`,
    reason: "phase7_quarantine_probe",
    expectedState: {
      media_state: "soft_deleted",
    },
  }, contentAdminCtx);
  await setMediaReferenceHealth(db, "stale");
  const mediaPurgeBlocked = await expectFailure(
    () => mediaPurgeAsset.run({
      targetType: "topup_proof",
      targetId: mediaRequestId,
      sourceCollection: "merchant_topup_requests",
      sourceDocumentId: mediaRequestId,
      mediaUrl,
      commandId: `${runId}_media_purge_blocked`,
      correlationId: `${runId}_media_purge_blocked`,
      reason: "phase7_purge_guard",
      expectedState: {
        media_state: "quarantined",
        reference_count: 0,
        reference_index_health: "healthy",
      },
    }, contentAdminCtx),
    {
      code: "failed-precondition",
      messageIncludes: "media_purge_reference_index_unhealthy",
    },
  );
  const mediaDenied = await expectFailure(
    () => mediaSoftDeleteAsset.run({
      targetType: "topup_proof",
      targetId: `${mediaRequestId}_deny`,
      sourceCollection: "merchant_topup_requests",
      sourceDocumentId: `${mediaRequestId}_deny`,
      mediaUrl: `${mediaUrl}.deny`,
      commandId: `${runId}_media_denied`,
      reason: "phase7_denied_role_check",
    }, plainCtx),
    {
      code: "permission-denied",
      messageIncludes: "admin",
    },
  );
  evidence.media = {
    readCounts: {
      topupProofs: mediaRead.topupProofs.length,
      venuePhotos: mediaRead.venuePhotos.length,
      offerImages: mediaRead.offerImages.length,
      storyImages: mediaRead.storyImages.length,
    },
    referenceIndexBefore: mediaRead.referenceIndex.status,
    referenceCheck: mediaReferenceCheck,
    softDelete: mediaSoftDelete,
    quarantine: mediaQuarantine,
    purgeBlocked: mediaPurgeBlocked,
    deniedForPlainUser: mediaDenied,
  };

  evidence.completedAt = new Date().toISOString();
  evidence.decision = {
    rehearsalStatus:
      evidence.config.rehearsal.pricingRestoredToBaseline &&
      evidence.content.deniedByFinanceRole.passed &&
      evidence.reviews.expectedStateConflict.passed &&
      evidence.media.purgeBlocked.passed
        ? "PASS"
        : "FAIL",
    goLiveRecommendation: "NOT_READY",
    phase7Recommendation: "ACCEPTED_WITH_FOLLOW_UP",
    remainingFollowUps: [
      "Live browser HTTP callable transport smoke for /admin/config, /admin/media, and /admin/content with auth/app-check envs is still not evidenced.",
      "This rehearsal validates callable logic against live Firestore using service-account execution, not end-user browser transport.",
    ],
  };

  await writeJson(outputPath, evidence);
  console.log(JSON.stringify({
    ok: true,
    outputPath,
    rehearsalStatus: evidence.decision.rehearsalStatus,
    projectId,
  }));
}

run().catch(async (error) => {
  console.error(JSON.stringify({
    ok: false,
    error: normalizeError(error),
  }));
  process.exit(1);
});
