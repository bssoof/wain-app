export type AdminRequestHardeningDecision =
  | { kind: "allow" }
  | { kind: "reject"; status: 400 | 404; reason: string }
  | { kind: "redirect"; status: 307; location: string; reason: string };

export type AdminRequestHardeningInput = {
  pathname: string;
  rawUrl: string;
  headers: Headers;
};

const PROTECTED_ADMIN_PREFIX = "/admin";
const PUBLIC_ADMIN_PATHS = new Set([
  "/admin/sign-in",
  "/admin/access-denied",
]);

export function evaluateAdminRequestHardening(
  input: AdminRequestHardeningInput,
): AdminRequestHardeningDecision {
  const rawUrl = input.rawUrl.toLowerCase();
  const pathname = input.pathname || "/";

  if (hasMalformedPathEncoding(rawUrl)) {
    return {
      kind: "reject",
      status: 400,
      reason: "malformed_path_encoding",
    };
  }

  if (input.headers.has("next-action")) {
    return {
      kind: "reject",
      status: 400,
      reason: "server_actions_disabled",
    };
  }

  if (isProtectedAdminPath(pathname) && isRscRequest(input.headers)) {
    const stateTree = input.headers.get("next-router-state-tree");

    if (!stateTree) {
      return {
        kind: "redirect",
        status: 307,
        location: `/admin/sign-in?next=${encodeURIComponent(pathname)}`,
        reason: "anonymous_rsc_without_state_tree",
      };
    }

    if (isMalformedRouterStateTree(stateTree)) {
      return {
        kind: "reject",
        status: 400,
        reason: "malformed_router_state_tree",
      };
    }
  }

  return { kind: "allow" };
}

function isProtectedAdminPath(pathname: string): boolean {
  if (!pathname.startsWith(PROTECTED_ADMIN_PREFIX)) return false;
  return !PUBLIC_ADMIN_PATHS.has(pathname);
}

function isRscRequest(headers: Headers): boolean {
  return headers.get("rsc") === "1";
}

function hasMalformedPathEncoding(rawUrl: string): boolean {
  return (
    rawUrl.includes("%00") ||
    rawUrl.includes("%c0%af") ||
    rawUrl.includes("%c1%9c")
  );
}

function isMalformedRouterStateTree(value: string): boolean {
  const normalized = safeDecodeURIComponent(value).replace(/\s+/g, "");
  return (
    normalized === "" ||
    normalized === "[]" ||
    normalized === '[""]' ||
    normalized === "[null]"
  );
}

function safeDecodeURIComponent(value: string): string {
  try {
    return decodeURIComponent(value);
  } catch {
    return value;
  }
}
