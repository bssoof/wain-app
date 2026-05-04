import { NextResponse } from "next/server";

import { canAccessRoute } from "@/lib/auth/guard-api";
import { getCurrentAdminSession } from "@/lib/auth/session-server";
import {
  isAdminRouteKey,
  type AdminRouteKey,
} from "@/lib/navigation/admin-contract";
import {
  ADMIN_WARMUP_MAX_SERVER_TASKS,
  getAdminServerWarmupRouteKeys,
} from "@/lib/navigation/admin-warmup-policy";
import { claimAdminWarmupRequest } from "@/lib/admin/admin-warmup-dedupe";
import { loadConfigGovernanceSnapshot } from "@/lib/config/config-read-loader";
import {
  loadOfferModerationSnapshot,
  loadStoryModerationSnapshot,
} from "@/lib/content/content-read-loader";
import {
  loadReadinessRead,
  loadTopUpQueueRead,
  loadWalletLedgerRead,
} from "@/lib/finance/finance-read-loader";
import { loadMediaCenterBaseline } from "@/lib/media/media-center-baseline";
import { loadReviewModerationSnapshot } from "@/lib/reviews/review-moderation-loader";
import { loadVenueDirectoryRead } from "@/lib/venues/venue-directory-read-loader";

export const runtime = "nodejs";

const DEFAULT_WARMUP_TASK_TIMEOUT_MS = 3_500;
const DEFAULT_WARMUP_DEDUPE_TTL_MS = 60_000;

type WarmupTask = {
  key: string;
  routeKey: AdminRouteKey;
  run: () => Promise<unknown>;
};

type WarmupTaskResult = {
  key: string;
  ok: boolean;
  durationMs: number;
  reason?: string;
};

export async function POST(request: Request) {
  const session = await getCurrentAdminSession();
  if (!session) {
    return noStoreJson(
      {
        ok: false,
        message: "unauthenticated",
      },
      { status: 401 },
    );
  }

  const timeoutMs = resolveWarmupTaskTimeoutMs();
  const maxTasks = resolveWarmupMaxTasks();
  const requestedRouteKeys = await readRequestedRouteKeys(request);
  const routeKeys = getAdminServerWarmupRouteKeys(session, {
    maxServerTasks: maxTasks,
    requestedRouteKeys,
  });
  const tasksByRouteKey = new Map(
    buildWarmupTasks().map((task) => [task.routeKey, task]),
  );
  const tasks = routeKeys
    .map((routeKey) => tasksByRouteKey.get(routeKey))
    .filter((task): task is WarmupTask => Boolean(task))
    .filter((task) => canAccessRoute(session, task.routeKey));

  if (!claimAdminWarmupRequest(session.uid, resolveWarmupDedupeTtlMs())) {
    return noStoreJson({
      ok: true,
      skipped: true,
      reason: "recent_duplicate",
      warmed: 0,
      failed: 0,
      timeoutMs,
      maxTasks,
      results: [],
    });
  }

  const results = await Promise.all(
    tasks.map((task) => runWarmupTask(task, timeoutMs)),
  );

  const failedTasks = results.filter((result) => !result.ok);
  return noStoreJson(
    {
      ok: failedTasks.length === 0,
      skipped: false,
      warmed: tasks.length,
      failed: failedTasks.length,
      timeoutMs,
      maxTasks,
      results,
    },
    {
      status: failedTasks.length === 0 ? 200 : 207,
    },
  );
}

function buildWarmupTasks(): WarmupTask[] {
  return [
    {
      key: "dashboard_topups",
      routeKey: "topups",
      run: () => loadTopUpQueueRead(),
    },
    {
      key: "dashboard_readiness",
      routeKey: "readiness",
      run: () => loadReadinessRead(),
    },
    {
      key: "wallet_audit",
      routeKey: "wallet_audit",
      run: () => loadWalletLedgerRead(),
    },
    {
      key: "venues",
      routeKey: "venues",
      run: () => loadVenueDirectoryRead(),
    },
    {
      key: "media",
      routeKey: "media",
      run: () => loadMediaCenterBaseline(),
    },
    {
      key: "content_offers",
      routeKey: "content_offers",
      run: () => loadOfferModerationSnapshot(),
    },
    {
      key: "content_stories",
      routeKey: "content_stories",
      run: () => loadStoryModerationSnapshot(),
    },
    {
      key: "reviews_moderation",
      routeKey: "reviews_moderation",
      run: () => loadReviewModerationSnapshot(),
    },
    {
      key: "config",
      routeKey: "config",
      run: () => loadConfigGovernanceSnapshot(),
    },
  ];
}

async function runWarmupTask(
  task: WarmupTask,
  timeoutMs: number,
): Promise<WarmupTaskResult> {
  const startedAt = performance.now();

  try {
    await Promise.race([
      task.run(),
      new Promise<never>((_, reject) => {
        setTimeout(() => {
          reject(new Error(`warmup_timeout:${task.key}:${timeoutMs}ms`));
        }, timeoutMs);
      }),
    ]);

    return {
      key: task.key,
      ok: true,
      durationMs: Math.round(performance.now() - startedAt),
    };
  } catch (error) {
    return {
      key: task.key,
      ok: false,
      durationMs: Math.round(performance.now() - startedAt),
      reason: normalizeError(error),
    };
  }
}

function resolveWarmupTaskTimeoutMs(): number {
  const explicit = parsePositiveInt(
    process.env.WAIN_ADMIN_WARMUP_TASK_TIMEOUT_MS,
  );
  return explicit ?? DEFAULT_WARMUP_TASK_TIMEOUT_MS;
}

function resolveWarmupMaxTasks(): number {
  const explicit = parsePositiveInt(process.env.WAIN_ADMIN_WARMUP_MAX_TASKS);
  return Math.min(explicit ?? ADMIN_WARMUP_MAX_SERVER_TASKS, 6);
}

function resolveWarmupDedupeTtlMs(): number {
  const explicit = parseNonNegativeInt(
    process.env.WAIN_ADMIN_WARMUP_DEDUPE_TTL_MS,
  );
  return Math.min(explicit ?? DEFAULT_WARMUP_DEDUPE_TTL_MS, 300_000);
}

function parsePositiveInt(value: string | undefined): number | undefined {
  if (!value) {
    return undefined;
  }

  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : undefined;
}

function parseNonNegativeInt(value: string | undefined): number | undefined {
  if (!value) {
    return undefined;
  }

  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : undefined;
}

async function readRequestedRouteKeys(
  request: Request,
): Promise<AdminRouteKey[] | undefined> {
  try {
    const body = (await request.json()) as { routeKeys?: unknown };
    if (!Array.isArray(body.routeKeys)) {
      return undefined;
    }

    return Array.from(new Set(body.routeKeys.filter(isAdminRouteKey)));
  } catch {
    return undefined;
  }
}

function noStoreJson(
  body: Record<string, unknown>,
  init?: ResponseInit,
): NextResponse {
  const response = NextResponse.json(body, init);
  response.headers.set("Cache-Control", "no-store, max-age=0");
  return response;
}

function normalizeError(value: unknown): string {
  if (value instanceof Error && value.message.trim().length > 0) {
    return value.message;
  }

  if (typeof value === "string" && value.trim().length > 0) {
    return value;
  }

  return "unknown_error";
}
