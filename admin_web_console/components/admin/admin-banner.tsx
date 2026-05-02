"use client";

import { useEffect, useState } from "react";
import type { HealthReport, CheckResult } from "@/lib/admin/config-health/types";

const BANNER_POLL_INTERVAL_MS = 60_000;
const BANNER_DISMISS_KEY_PREFIX = "wain_admin_step_up_banner_dismissed:";

type BannerSeverity = "info" | "warning" | "critical";

type BannerSnapshot = {
  message: string;
  severity: BannerSeverity;
  messageHash: string;
};

export function AdminBanner() {
  const [banner, setBanner] = useState<BannerSnapshot | null>(null);
  const [dismissedHash, setDismissedHash] = useState<string | null>(null);

  useEffect(() => {
    let isDisposed = false;

    const refreshBanner = async () => {
      try {
        const response = await fetch("/api/admin/step-up/banner", {
          cache: "no-store",
          credentials: "include",
        });
        if (isDisposed) {
          return;
        }

        if (!response.ok) {
          setBanner(null);
          return;
        }

        const payload = asRecord(await response.json());
        let severity = normalizeBannerSeverity(payload?.bannerSeverity);
        let composedMessage: string | undefined;
        const configHealth = payload?.configHealth as HealthReport | undefined;
        if (configHealth && configHealth.checks) {
          const badChecks: CheckResult[] = configHealth.checks.filter(
            (c: CheckResult) => c.status !== "ok" && c.message
          );
          if (configHealth.summary.errorCount > 0) {
            severity = "critical";
          } else if (configHealth.summary.warnCount > 0 || configHealth.summary.unknownCount > 0) {
            severity = severity === "critical" ? "critical" : "warning";
          }
          if (badChecks.length > 0) {
            const configMsg = badChecks.map((c: CheckResult) => c.message).join(" | ");
            composedMessage = typeof payload?.bannerMessage === "string" && payload.bannerMessage.trim()
              ? `${configMsg}\n${payload.bannerMessage.trim()}`
              : configMsg;
          }
        }
        const finalPayload = payload
          ? {
              ...payload,
              bannerMessage: composedMessage !== undefined ? composedMessage : payload.bannerMessage,
              bannerSeverity: severity,
            }
          : payload;
        const rawMessage =
          typeof finalPayload?.bannerMessage === "string"
            ? finalPayload.bannerMessage.trim()
            : "";

        if (!rawMessage) {
          setBanner(null);
          return;
        }

        const messageHash = hashBannerMessage(rawMessage);
        setBanner({
          message: rawMessage,
          severity: normalizeBannerSeverity(finalPayload?.bannerSeverity),
          messageHash,
        });
      } catch {
        if (!isDisposed) {
          setBanner(null);
        }
      }
    };

    void refreshBanner();
    const intervalHandle = window.setInterval(() => {
      void refreshBanner();
    }, BANNER_POLL_INTERVAL_MS);

    return () => {
      isDisposed = true;
      window.clearInterval(intervalHandle);
    };
  }, []);

  useEffect(() => {
    if (!banner) {
      setDismissedHash(null);
      return;
    }

    const storageKey = getDismissStorageKey(banner.messageHash);
    const isDismissed = window.sessionStorage.getItem(storageKey) === "1";
    setDismissedHash(isDismissed ? banner.messageHash : null);
  }, [banner]);

  if (!banner || dismissedHash === banner.messageHash) {
    return null;
  }

  const dismissBanner = () => {
    const storageKey = getDismissStorageKey(banner.messageHash);
    window.sessionStorage.setItem(storageKey, "1");
    setDismissedHash(banner.messageHash);
  };

  return (
    <section
      className={`admin-step-up-banner admin-step-up-banner--${banner.severity}`}
      role="status"
      aria-live="polite"
      data-testid="admin-step-up-banner"
    >
      <p className="admin-step-up-banner__message">{banner.message}</p>
      <button
        type="button"
        className="admin-step-up-banner__dismiss"
        onClick={dismissBanner}
      >
        إخفاء
      </button>
    </section>
  );
}

function normalizeBannerSeverity(value: unknown): BannerSeverity {
  return value === "warning" || value === "critical" || value === "info"
    ? value
    : "info";
}

function asRecord(value: unknown): Record<string, unknown> | undefined {
  return value && typeof value === "object"
    ? (value as Record<string, unknown>)
    : undefined;
}

function getDismissStorageKey(messageHash: string): string {
  return `${BANNER_DISMISS_KEY_PREFIX}${messageHash}`;
}

function hashBannerMessage(message: string): string {
  let hash = 5381;
  for (let i = 0; i < message.length; i += 1) {
    hash = (hash * 33) ^ message.charCodeAt(i);
  }

  return Math.abs(hash >>> 0).toString(36);
}
