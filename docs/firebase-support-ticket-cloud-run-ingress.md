# Subject

Restrict Cloud Run ingress and rotate exposed URL for SSR managed by Firebase Hosting Frameworks (Next.js)

---

# Project

| Field | Value |
|---|---|
| Firebase project ID | `wain-d2e28` |
| Hosting site | `wain-admin` |
| Production URL | https://wain-admin.web.app |
| Cloud Run service | `ssrwainadmin` (region `us-central1`) |
| Direct Cloud Run URL (leaked) | https://ssrwainadmin-wvn5fhzfsq-uc.a.run.app |
| Internal alias observed in 302 redirects | `fh-0d492fa2b30328db---ssrwainadmin-wvn5fhzfsq-uc.a.run.app` |

---

# Issue 1 — Cloud Run ingress is INGRESS_TRAFFIC_ALL

The Cloud Run service `ssrwainadmin` was created and is managed by Firebase Hosting Frameworks (Next.js SSR). Its current ingress setting is `INGRESS_TRAFFIC_ALL`.

We attempted to restrict ingress to `internal-and-cloud-load-balancing` using:

```
gcloud run services update ssrwainadmin \
  --region us-central1 \
  --ingress internal-and-cloud-load-balancing
```

Google rejected the change because the service is managed by Firebase Frameworks — the update attempts to create a new revision with the same name as the existing one, which fails.

**Result:** Ingress has remained `INGRESS_TRAFFIC_ALL`. We cannot restrict it through normal `gcloud` tooling.

**Ask:** We need ingress restricted to `internal-and-cloud-load-balancing` without breaking Firebase Frameworks' management of the service. Please advise on the supported path to achieve this, or apply the change on our behalf.

---

# Issue 2 — Direct Cloud Run URL bypasses Firebase Hosting CDN

The direct Cloud Run URL (`https://ssrwainadmin-wvn5fhzfsq-uc.a.run.app`) is publicly reachable. An external penetration test confirmed the following:

### 2a. Direct access bypasses all Firebase Hosting CDN protections

```bash
curl -s -o /dev/null -w "%{http_code}" https://ssrwainadmin-wvn5fhzfsq-uc.a.run.app
# Returns: 200 with full admin app HTML
```

Any client that knows the Cloud Run URL can reach the SSR application directly, bypassing Firebase Hosting CDN headers, caching rules, and any CDN-layer access controls.

### 2b. Path-encoding bypass at Firebase Hosting/CDN layer leaks the Cloud Run URL

```bash
curl -v "https://wain-admin.web.app/admin/..%2fapi/admin/session"
# Returns: 302 redirect to https://ssrwainadmin-wvn5fhzfsq-uc.a.run.app/...
```

A path containing `..%2f` causes the Firebase Hosting CDN layer to issue a `302` redirect whose `Location` header contains the internal Cloud Run URL. This exposes the direct URL to any external observer.

### 2c. Cross-user session cookie clearing via CDN

```bash
curl -X DELETE "https://wain-admin.web.app/%2fapi%2fadmin%2fsession"
# Returns: 200 — clears wain_admin_session and __session cookies
```

A `DELETE` request with an encoded path through the CDN successfully clears session cookies, enabling a cross-user logout vector.

---

# Severity / Context

- This is the **admin panel for finance operations** (top-up approvals, wallet reversals).
- Step-up authentication is implemented but currently running in `log_only` observation mode before enforcement.
- **App-layer mitigations already deployed:**
  - Middleware rejects `Next-Action`, RSC probes, malformed `Next-Router-State-Tree`, null-byte paths, and overlong-Unicode paths.
  - `Content-Security-Policy` (Report-Only), `X-Frame-Options`, and `X-Content-Type-Options: nosniff` headers added.
  - Session route returns `400` on malformed JSON body.
- **Unresolved at the infrastructure layer:**
  - Pre-app `500` errors from Functions Framework body-parser on malformed requests.
  - The CDN path-encoding bypass (Issue 2b above).
  - The unrestricted Cloud Run ingress (Issue 1 above).

---

# Reproduction

**PoC 1 — Direct Cloud Run access (bypasses CDN):**

```bash
curl -s -o /dev/null -w "%{http_code}\n" \
  https://ssrwainadmin-wvn5fhzfsq-uc.a.run.app
```

Expected: blocked or `403`.  
Actual: `200` with full admin app HTML.

**PoC 2 — CDN path-encoding bypass leaks Cloud Run URL:**

```bash
curl -s -D - -o /dev/null \
  "https://wain-admin.web.app/admin/..%2fapi/admin/session"
```

Expected: request handled by CDN without exposing origin.  
Actual: `302` redirect with `Location` header pointing to `https://ssrwainadmin-wvn5fhzfsq-uc.a.run.app/...`.

**PoC 3 — Cross-user session clearing via encoded DELETE:**

```bash
curl -s -X DELETE -D - -o /dev/null \
  "https://wain-admin.web.app/%2fapi%2fadmin%2fsession"
```

Expected: `405` or `400`.  
Actual: `200`, `Set-Cookie` headers clear `wain_admin_session` and `__session`.

---

# Asks

1. **Ingress restriction:** Provide a supported path to restrict ingress to `internal-and-cloud-load-balancing` on a Firebase Frameworks-managed Cloud Run service (`ssrwainadmin` in project `wain-d2e28`, region `us-central1`), or apply the change on our behalf.

2. **URL rotation:** Provide an option to rotate or hide the direct Cloud Run URL (`https://ssrwainadmin-wvn5fhzfsq-uc.a.run.app`) so that the currently leaked URL is no longer valid.

3. **CDN path-encoding policy:** Confirm whether Firebase Hosting/CDN is expected to normalize percent-encoded path traversal sequences (e.g. `..%2f`) before routing to the origin, and whether the `302` redirect exposing the internal Cloud Run URL is a known issue or intended behavior.

---

*Ticket prepared for Firebase Support — paste into Firebase Console > Support > New case.*
