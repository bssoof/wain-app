# Menu System Transformation Plan (Image -> Structured Menu)

## 1) Objective
Transform menu management from image-only/manual entries into a structured and versioned system with venue-type templates and a safe import pipeline.

Primary goals:
- Venue-type categories (cafe, restaurant, etc.).
- Structured data for categories and items.
- Safe import pipeline from images/PDF with strict review gates.
- Stable publish/rollback using version pointers.

Out of scope in initial foundation:
- Modifiers (size/extras) are deferred until after versioning and import stability.

## 2) Closed Architecture Decisions
1. Versions storage location: use venue subcollections, not a top-level `menu_versions`.
2. Active pointer denormalization: store `active_menu_version_id` on venue document.
3. Draft lifecycle: active is immutable; merchant edits draft only.
4. Publish/rollback: client-side Firestore transactions (no dedicated publish/rollback Cloud Functions).
5. OCR provider (locked now): Google Cloud Vision API (Document Text Detection).
6. LLM assist (later phase): Gemini on Vertex AI, limited to unresolved low-confidence lines.
7. Migration runner: one-off Admin script with checkpoints and resume; Cloud Run batch job only if scale requires.

## 3) Data Model (Revised)

### 3.1 Venue document
`venues/{venueId}`
- `active_menu_version_id: string?`
- existing venue fields...

### 3.2 Venue menu config
`venues/{venueId}/menu_config/main`
- `draft_version_id: string?`
- `venue_type: string` (`cafe|restaurant|fast_food|sweets|juice_bar|other`)
- `currency: string` (default `ILS`)
- `migration_status: "not_started" | "in_progress" | "done" | "failed"`
- `last_migration_run_id: string?`
- `updated_at: timestamp`

### 3.3 Menu versions (subcollection under venue)
`venues/{venueId}/menu_versions/{versionId}`
- `status: "draft" | "active" | "archived"`
- `source: "manual" | "import" | "migration"`
- `created_by: string`
- `created_at: timestamp`
- `published_at: timestamp?`
- `item_count: int` (denormalized snapshot, written at publish/migration verification; not updated per draft edit)
- `category_count: int` (same policy as `item_count`)
- `last_counted_at: timestamp?`

Subcollections:
- `venues/{venueId}/menu_versions/{versionId}/categories/{categoryId}`
- `venues/{venueId}/menu_versions/{versionId}/items/{itemId}`

### 3.4 Category document
`venues/{venueId}/menu_versions/{versionId}/categories/{categoryId}`
- `key: string`
- `name_ar: string`
- `name_en: string`
- `sort_order: int`
- `is_custom: bool`

### 3.5 Item document
`venues/{venueId}/menu_versions/{versionId}/items/{itemId}`
- `category_id: string`
- `name_ar: string`
- `name_en: string`
- `description_ar: string`
- `description_en: string`
- `price: number?`
- `currency: string`
- `market_price_flag: bool`
- `photo_url: string`
- `is_available: bool`
- `is_featured: bool`
- `sort_order: int`
- `tags: string[]`
- `source: "manual" | "import" | "migration"`
- `confidence_score: number?`
- `needs_review: bool`

### 3.6 Import jobs (scoped by venue)
`venues/{venueId}/menu_import_jobs/{jobId}`
- `version_id: string`
- `status: "uploaded" | "ocr_done" | "extracted" | "mapped" | "review_required" | "published" | "failed"`
- `idempotency_key: string`
- `input_files: string[]`
- `ocr_output_ref: string?`
- `extracted_output_ref: string?`
- `mapped_output_ref: string?`
- `error_code: string?`
- `error_message: string?`
- `created_by: string`
- `created_at: timestamp`
- `updated_at: timestamp`

Admin monitoring note:
- Because jobs are subcollections, admin dashboards must use collection-group queries on `menu_import_jobs` with proper indexes.

## 4) Security Rules Strategy (Why subcollection)
Use path-derived `venueId` for ownership checks, not document fields.

Rule shape:
- `match /venues/{venueId}/menu_versions/{versionId}`
- `match /venues/{venueId}/menu_versions/{versionId}/items/{itemId}`
- `match /venues/{venueId}/menu_versions/{versionId}/categories/{categoryId}`

Ownership check:
- Validate merchant ownership against `venueId` from path.
- Do not trust client-provided `venue_id` fields for authorization.

Result:
- Simpler rules.
- Fewer authorization pitfalls.
- Cleaner query model for per-venue menu operations.

## 5) Customer Read Path (Optimized)
Read path for customer app:
1. Read `venues/{venueId}` (already needed for venue screen) and get `active_menu_version_id`.
2. If active version exists, read:
   - `venues/{venueId}/menu_versions/{activeVersionId}/categories`
   - `venues/{venueId}/menu_versions/{activeVersionId}/items`
3. If no active version, fallback to legacy `venues/{venueId}/menu_items`.

Caching policy:
- Reuse already loaded venue document in state providers.
- Cache menu payload by key `{venueId}:{activeVersionId}` in memory.
- Enable Firestore offline persistence for repeated opens.

Net effect:
- No dedicated `menu_config` read on customer path.
- Menu reads drop from 3 reads to 2 reads on hot path (plus venue read that page already performs).

## 6) Publish and Draft Semantics (Locked)

### 6.1 Merchant editing model
1. Merchant cannot edit active version directly.
2. If `draft_version_id` exists, edits target that draft.
3. If no draft exists, system creates a new draft by cloning all categories and items from current active version.

Known V1 trade-off:
- Draft cloning is full-copy and can be write-heavy.
- Accepted in V1 for expected scale (<100 items/venue).
- Optimization (copy-on-write / delta drafts) is explicitly deferred.

### 6.2 Publish transaction (client-side)
Preflight (outside transaction):
1. Run aggregate counts on draft subcollections:
   - categories count
   - items count
2. Block publish if item count is zero.

Transaction steps:
1. Read `venues/{venueId}`.
2. Read `venues/{venueId}/menu_config/main`.
3. Read draft version doc from `draft_version_id`.
4. Validate `draft.status == "draft"`.
5. If venue has old active version, read old active version doc.
6. Write `venues/{venueId}.active_menu_version_id = draftVersionId`.
7. Write draft version status to `active`, set `published_at`, and write preflight `item_count/category_count` + `last_counted_at`.
8. If old active exists, write old active status to `archived`.
9. Write `menu_config/main.draft_version_id = null`.
10. Write audit fields (`last_published_by`, `last_published_at`) in config.

Decision:
- After publish, `draft_version_id` becomes `null`.
- Next edit creates a fresh draft from active.

### 6.3 Transaction retry policy (client)
- Firestore transaction retries are required for contention scenarios.
- Client will retry on retryable errors (for example `aborted`) with exponential backoff.
- Default retry policy: 3 attempts (`150ms`, `500ms`, `1200ms` jittered backoff).
- If all retries fail, show merchant-friendly error and keep draft unchanged.

### 6.4 Rollback transaction (client-side)
1. Read venue doc and target version doc.
2. Validate target is owned by same venue and status is `archived` or `active`.
3. Archive current active (if different).
4. Activate target version.
5. Update venue `active_menu_version_id`.
6. Keep `draft_version_id` unchanged (or null if none).
7. Write rollback audit fields.

## 7) Migration Strategy (Legacy -> Versioned)

### 7.1 Runner choice
Default runner:
- Admin script (Node/TS) with checkpoint document, resumable batches.
- Use Cloud Run batch only if venue volume requires distributed execution.

### 7.2 Migration status model
`venues/{venueId}/menu_config/main`:
- `migration_status`
- `last_migration_run_id`

`venues/{venueId}/menu_versions/{versionId}`:
- `expected_items_count`
- `migrated_items_count`
- `verified_at`
- `migration_hash`

### 7.3 Per-venue migration steps
1. Set `migration_status=in_progress`.
2. Read legacy `venues/{venueId}/menu_items` and compute `expected_items_count`.
3. Create migration version doc (deterministic id: e.g. `migrated_v1`) if missing.
4. Copy items idempotently into version `items` subcollection.
5. Build categories and write idempotently.
6. Update `migrated_items_count`.
7. Verify `migrated_items_count == expected_items_count`.
8. Set venue `active_menu_version_id` and version `status=active` only after verification passes.
9. Set `migration_status=done`; otherwise `failed` with error metadata.

### 7.4 Failure and resume guarantees
- Re-running migration for same venue must not duplicate items.
- Partial venue migration stays `in_progress` or `failed` until verified completion.
- Legacy data remains untouched during rollout.

## 8) Import Pipeline (Safe by Design)
State machine:
`uploaded -> ocr_done -> extracted -> mapped -> review_required -> published`

Guardrails:
- Monotonic transitions only.
- No direct publish without validation.
- Stage retries are idempotent.

Validation:
- JSON schema validation.
- Business rules (`name_ar` required, and `price` or `market_price_flag`).

Confidence:
- `final_conf = ocr_conf * parsing_conf * mapping_conf`.
- `needs_review=true` below threshold.

## 9) OCR and LLM Strategy (Clarified)

### 9.1 OCR provider (locked)
- Google Cloud Vision API (Document Text Detection).
- Inputs: image/PDF pages.
- Outputs used: text blocks, bounding boxes, confidence.

### 9.2 LLM assist (later phase)
Provider:
- Gemini on Vertex AI.

Prompt/input strategy:
- Send normalized OCR lines + bounding box metadata + venue type template context.
- Do not send full images to LLM in first rollout.
- Require strict JSON schema output.

Call limits and cost controls:
- `max_llm_calls_per_job = 2`.
- Token caps per call via config.
- If limits exceeded, skip LLM and keep items in review_required.
- Track token usage per job and compute cost in monitoring dashboard.

## 10) Delivery Plan (10-12 Weeks)

### Weeks 1-2: Foundation (reduced scope)
- Implement version pointers and new subcollection schema.
- Implement client-side draft/publish/rollback transactions.
- Implement customer read path via venue `active_menu_version_id` + legacy fallback.
- No modifiers.

Acceptance:
- Merchant can draft, publish, rollback safely.
- Customer sees active snapshot only.

### Week 3: Migration pilot
- Build migration script and checkpointing.
- Migrate pilot venues and verify counts.
- Validate rollback to legacy fallback if needed.

Acceptance:
- Migration idempotency and verification confirmed.

### Weeks 4-5: Import skeleton
- Add job docs and state machine transitions.
- Add upload flow and resumable processing.

### Weeks 6-7: OCR phase
- Integrate Vision OCR and parser.
- Multi-page merge baseline and duplicate suppression.

### Weeks 8-9: Mapping and review UX
- Category mapping.
- Low-confidence review tools.

### Week 10: Controlled LLM assist
- Enable LLM only for unresolved segments.
- Enforce strict schema and limits.

### Weeks 11-12: Hardening and release
- Rules and indexes hardening.
- Emulator E2E + UAT + release checklist.
- Add collection-group indexes for admin monitoring of `menu_import_jobs`.

## 11) Backend Scope (Reduced Functions)
Keep only:
- `createMenuImportJob`
- `processMenuImport`
- `runMenuOcr`
- `extractMenuCandidates`
- `mapExtractedMenu`

No dedicated `publishMenuVersion` / `rollbackMenuVersion` in this phase.

## 11.1 Required indexes (minimum)
- Collection group: `menu_import_jobs` on `(status ASC, updated_at DESC)` for failed-jobs/admin monitoring.
- Collection group: `menu_import_jobs` on `(created_by ASC, created_at DESC)` for operator/user audit views.

## 12) Test Plan
Unit:
- Publish/rollback guard logic.
- Parsing and confidence math.
- Migration verification logic.

Integration (emulator):
- Draft -> publish -> rollback transactions.
- Migration resume/idempotency with partial failures.
- Import state transitions and retry behavior.

UI/Widget:
- Merchant draft workflow.
- Customer active-read + fallback path.
- Review flows for low-confidence items.

## 13) Immediate Execution Order
1. Refactor schema to `venues/{venueId}/menu_versions/...`.
2. Add venue-level `active_menu_version_id` and adjust read providers.
3. Implement draft/publish/rollback client transactions.
4. Implement migration script with expected/migrated count verification.
5. Add rules and emulator tests for all above before OCR work starts.

## 14) Risk Controls (Locked)

### 14.1 Full-copy storage growth (Draft clone overhead)
Control policy:
- Keep only: `active` + current `draft` + latest 5 `archived` versions per venue.
- Add retention cleanup for archived versions older than 30 days.
- Never auto-delete `active` or current `draft`.

Execution:
- Weekly cleanup job/script:
  - query `venues/{venueId}/menu_versions` where `status=archived`
  - sort by `published_at DESC`
  - preserve latest 5, delete older than retention window
- Log deletion summary per run (venueId, deleted_versions, deleted_items_count).

Acceptance checks:
- No venue keeps more than 7 versions (`active + draft + 5 archived`) without an explicit override.
- Storage growth remains bounded during repeated publish cycles.

### 14.2 Firestore index budget pressure (admin collection-group queries)
Control policy:
- Phase-1 admin filters are limited to:
  - `status + updated_at`
  - `created_by + created_at`
- No extra `menu_import_jobs` indexes unless justified by observed operational need.

Execution:
- Maintain an "index budget" rule in planning/review:
  - every new index request must include query frequency and user-facing impact
  - prefer coarse filters + client-side secondary filtering in early phases

Acceptance checks:
- Only the two baseline `menu_import_jobs` collection-group indexes are required for initial release.
- Admin dashboards remain functional without high-cardinality multi-field filters.

### 14.3 Migration runner reliability (timeouts / partial failures)
Control policy:
- Migration runner must be resumable and idempotent by design.
- Partial progress must be checkpointed per run and per venue.

Execution:
- Persist run checkpoints in a dedicated run document (for example: `menu_migration_runs/{runId}`):
  - `last_processed_venue_id`
  - `processed_count`
  - `failed_count`
  - `updated_at`
- Use bounded batches (default 20 venues per cycle) with retry/backoff.
- Support explicit resume arguments: `--resume <runId>` and `--from-venue <venueId>`.

Acceptance checks:
- If migration stops at venue N, restart continues from N+1 (or configured checkpoint) without duplicating copied items.
- Re-running the same venue migration does not change item counts beyond expected idempotent state.
