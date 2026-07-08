# 📅 LottoGuard — DAY-BY-DAY BUILD PLAN
### Companion to LottoGuard_Build_Execution_Plan.docx v1.1 — pull this at the start of every build session

> ⚡ **AI AGENT INSTRUCTION — READ THIS FIRST:**
> The developer will tell you which day they're working on (e.g. "Build Day 12" or "Phase 2, Day 3"). Find that day below, read its **Build** list, **Files/Tables touched**, and **Done when** criteria, and work only within that day's scope unless the developer explicitly expands it.
> Do not start a day's work until the previous day's "Done when" criteria are met — check with the developer if you're unsure whether a prior day actually finished.
> Every day assumes `npx tsc --noEmit` passes and the standing rules in the Master Document (Section 12, Engineering Standards) are followed — no exceptions, no silent scope creep.
> If a day's task depends on a BLOCKED item (Section 7 of the Build Execution Plan — barcode uniqueness, MerchandiseCode, LSP credentials), that day is marked ⛔ and has a fallback noted. Check with the developer before improvising around a blocked dependency.

**Last updated:** July 8, 2026 — initial day-by-day breakdown, built from LottoGuard_Build_Execution_Plan.docx v1.1 (Decisions 25–36). Revised same day against v1.2 (Decisions 37–41: employee consent, data export, outage escalation, pricing deferral, staging timing) — see Day 11, Day 12, Day 63, and the Manual Support Processes section below for what changed.

**Kickoff confirmed:** Build starts Wednesday, July 8, 2026 exactly as planned — no changes to scope or sequence. Target pilot launch: Thursday, October 8, 2026 (end of Build Day 67). Dates below assume a standard Mon–Fri work week with no holidays/off-days factored in — adjust and re-run the date pass if any days are skipped.

**How day numbers work:** Each day has an absolute **Build Day** number (continuous across the whole project) and a **Phase/Week/Day** reference (matches the phase timeline). Either one can be used to look it up.

---

## PHASE 0 — OPS SETUP (Jul 8 – Jul 9, 2026)

**Objective:** Every piece of infrastructure exists and is verified working before a single feature line is written. Per Decision 33 — no Doppler, Sentry/Better Uptime/Checkly deliberately deferred to later phases.

### Build Day 1 — Wednesday, July 8, 2026 — Phase 0, Day 1
**Build:**
- Create GitHub repo `SmartAIITSolutions/lottoguard`, default branch `main`, branch protection on `main` (require PR + passing CI)
- Create new Supabase project (dedicated — not shared with Book With AI or SANAA)
- Create new Vercel project, link to the GitHub repo
- Set up Vercel environment variables (dev/preview/production) — no Doppler (Decision 33)
- Scaffold Next.js 14 + TypeScript project, push initial commit

**Files/Tables touched:** repo root, `package.json`, `next.config.js`, `.env.example` (documents required vars, no real secrets committed)

**Done when:** `npm run dev` runs locally, Vercel preview deploy succeeds on first PR, `main` is protected.

### Build Day 2 — Thursday, July 9, 2026 — Phase 0, Day 2
**Build:**
- GitHub Actions CI workflow: typecheck (`tsc --noEmit`) + build on every PR
- Add Semgrep GitHub Action (security scanning on every PR)
- Enable Dependabot (npm + GitHub Actions ecosystem)
- Create Linear team + initial board matching the 7 phases as epics
- Write `LottoGuard-MASTER.md` v1 in repo root (session-start reference, per existing template)

**Files/Tables touched:** `.github/workflows/ci.yml`, `.github/workflows/semgrep.yml`, `.github/dependabot.yml`, `LottoGuard-MASTER.md`

**Done when:** A test PR shows green CI + Semgrep + Dependabot all active; Linear board exists with 7 phase epics.

---

## PHASE 1 — FOUNDATION (Weeks 1–3, Build Days 3–17, Jul 10 – Jul 30, 2026)

**Objective:** Multi-tenant schema (Owner → many Stores) + full role system (Agency/Owner/Manager/Cashier) + Agency internal overview dashboard, from day one — per Decision 32. This phase is intentionally bigger than a typical "foundation" phase (Decision 36) — build the correct data shape once.

### Week 1 — Schema & Auth Core

**Build Day 3 — Friday, July 10, 2026 — Phase 1, Week 1, Day 1**
**Build:**
- Design full ERD: `organizations` (agencies), `owners`, `stores` (FK owner_id), `employees` (FK store_id, role enum: owner/manager/cashier), `packs`, `shifts`, `spot_checks`, `tallies`, `complaints`, `audit_log`
- Write Supabase migration 001: `organizations`, `owners`, `stores` tables with `owner_id` as one-to-many (one owner → many stores) — this is the Decision 32 structural change
- Migration naming convention: `YYYYMMDDHHMM_description.sql`

**Files/Tables touched:** `supabase/migrations/`, new tables: `organizations`, `owners`, `stores`

**Done when:** Migration applies cleanly on a fresh Supabase instance; an owner row can have 2+ store rows attached.

**Build Day 4 — Monday, July 13, 2026 — Phase 1, Week 1, Day 2**
**Build:**
- Migration 002: `employees` table (role enum, store_id FK, PIN hash field for device login)
- Supabase Auth setup: email/password + 2FA scaffolding for Owner/Manager/Agency roles
- Design PIN device-login flow separately from Supabase Auth sessions (cashier + manager shared-tablet use case)

**Files/Tables touched:** `employees` table, `lib/auth/`

**Done when:** A test Owner account can be created via Supabase Auth; a test Employee row can be created with a hashed PIN.

**Build Day 5 — Tuesday, July 14, 2026 — Phase 1, Week 1, Day 3**
**Build:**
- Write RLS policies for `stores`, `owners`, `employees` implementing the Access & Permissions Matrix (Build Execution Plan, Section 2): Agency sees all, Owner sees own stores only, Manager sees own store only, Cashier sees own shift only
- Write RLS test suite (Vitest + real local Supabase) proving cross-org data isolation

**Files/Tables touched:** `supabase/migrations/003_rls_policies.sql`, `tests/integration/rls/`

**Done when:** RLS test suite proves Owner A cannot query Owner B's stores under any circumstance, including via joins.

**Build Day 6 — Wednesday, July 15, 2026 — Phase 1, Week 1, Day 4**
**Build:**
- Migration 003: `packs`, `shifts` (shift_ownership), `spot_checks`, `tallies`, `complaints`, `audit_log` tables per the Master Document's Section 05 schema, adapted to the multi-store FK chain
- Key fields: `packs.pack_id`, `shifts.ticket_start`/`ticket_end`, `shifts.going_signed_by`/`incoming_signed_by`, `spot_checks.photo_metadata` (JSONB: lat/lng/timestamp/device_id/exif_present), `employees.risk_score`

**Files/Tables touched:** all remaining core tables

**Done when:** Full schema exists; ERD diagram matches deployed schema exactly.

**Build Day 7 — Thursday, July 16, 2026 — Phase 1, Week 1, Day 5**
**Build:**
- Add Sentry to the Next.js app (Decision 33 — first real users, starting with internal Agency use, exist from this point)
- `audit_log` trigger: every INSERT/UPDATE on `shifts`, `spot_checks`, `tallies` writes an append-only audit row (who/what/when/device)
- Write RLS policy: `audit_log` is never UPDATE/DELETE-able by anyone, including Owner

**Files/Tables touched:** `audit_log`, Supabase Edge Function or trigger, Sentry config

**Done when:** Sentry captures a deliberately-thrown test error in production preview; an audit_log row is unmodifiable via the Supabase client even as service-role in a test (only direct DB migration can touch it).

### Week 2 — Agency Role & Internal Dashboard

**Build Day 8 — Friday, July 17, 2026 — Phase 1, Week 2, Day 1**
**Build:**
- Next.js route groups: `app/(auth)/`, `app/(agency)/`, `app/(owner)/`, `app/(manager)/`, `app/(cashier)/` — role-gated layouts
- Middleware: redirect based on `employees.role` / Agency-org membership after login

**Files/Tables touched:** `app/(agency)/layout.tsx`, `app/(owner)/layout.tsx`, `middleware.ts`

**Done when:** Logging in as each of the 4 roles lands on the correct route group and cannot navigate into another role's routes (verified by RLS + route guard, not just hidden nav links).

**Build Day 9 — Monday, July 20, 2026 — Phase 1, Week 2, Day 2**
**Build:**
- Agency internal overview dashboard (Sitemap page 35): all client stores in one table — store name, owner, POS brand, confidence tier (Decision 31), MRR
- This is SmartAI's own ops view first, reseller-facing later (Decision 32)

**Files/Tables touched:** `app/(agency)/dashboard/page.tsx`

**Done when:** Logging in as Agency shows every store across every owner in one list, pulling from real seeded test data (3+ fake stores).

**Build Day 10 — Tuesday, July 21, 2026 — Phase 1, Week 2, Day 3**
**Build:**
- Agency billing overview page (Sitemap page 39 — early build, billing logic itself is still Stripe-standalone per the existing billing build rule)
- Store config profile schema: `stores.pos_brand`, `stores.pos_version`, `stores.integration_path` (enum matching Decision 24 priority list), `stores.confidence_tier` (Decision 31)

**Files/Tables touched:** `stores` table extension, `app/(agency)/billing/page.tsx`

**Done when:** Each store row shows its confidence tier, defaulting to lowest tier per Decision 31 with no manual override control visible anywhere in the UI.

**Build Day 11 — Wednesday, July 22, 2026 — Phase 1, Week 2, Day 4**
**Build:**
- Store & employee setup flow (Sitemap page 4 — guided onboarding wizard, Owner-facing): create store, set POS config profile, add first employee
- Owner consent checkbox (Decision 37): ToS language disclosing employee photo/activity monitoring, required before the wizard can be completed
- Wizard writes to `stores` + `employees` + fires the audit_log trigger

**Files/Tables touched:** `app/(owner)/onboarding/page.tsx`, `owners.consent_accepted_at`

**Done when:** A brand-new Owner account cannot complete the wizard without checking the consent box; the acceptance timestamp is recorded and immutable.

**Build Day 12 — Thursday, July 23, 2026 — Phase 1, Week 2, Day 5**
**Build:**
- Navigation shell for Owner: single-store view by default, store switcher component visible only if `owner.stores.count > 1` (multi-store data model in use immediately, per Decision 32, even though full network dashboard UI isn't built until Phase 5)
- PIN device login screen (Cashier + Manager shared-tablet flow)
- Employee consent interstitial (Sitemap page 46, Decision 37): one-time blocking screen shown at an employee's first-ever PIN login, before shift access is granted — records a timestamped acknowledgment, same evidentiary spirit as the audit trail elsewhere in the product

**Files/Tables touched:** `app/(owner)/layout.tsx` (store switcher), `app/(auth)/pin-login/page.tsx`, `employees.consent_acknowledged_at`

**Done when:** An Owner with 2 seeded stores sees a working store switcher; PIN login authenticates a seeded Cashier employee record; a fresh employee record is blocked from reaching shift screens until the consent interstitial is acknowledged, and a second login for the same employee does not show it again.

### Week 3 — Hardening & Phase Close-Out

**Build Day 13 — Friday, July 24, 2026 — Phase 1, Week 3, Day 1**
**Build:**
- Unit tests for every RLS policy written this phase (Vitest)
- Integration tests: `tests/integration/api/stores.test.ts`, `employees.test.ts`

**Files/Tables touched:** `tests/`

**Done when:** CI shows green on the full Phase 1 test suite.

**Build Day 14 — Monday, July 27, 2026 — Phase 1, Week 3, Day 2**
**Build:**
- Manager route group + Manager dashboard shell (Sitemap page 13) — empty-state only, no data yet since Scan Engine (Phase 2) doesn't exist
- Cashier route group + Active shift home shell (Sitemap page 8) — empty-state only

**Files/Tables touched:** `app/(manager)/dashboard/page.tsx`, `app/(cashier)/home/page.tsx`

**Done when:** All 4 roles have a working, correctly-gated (if mostly empty) home screen.

**Build Day 15 — Tuesday, July 28, 2026 — Phase 1, Week 3, Day 3**
**Build:**
- Notification preferences page (Sitemap page 43) — schema + UI, no actual SMS/push sending logic yet (that's Phase 5)
- Audit log viewer (Sitemap page 44) — Owner + Agency only, read-only table view

**Files/Tables touched:** `notification_preferences` table, `app/(owner)/audit-log/page.tsx`, `app/(agency)/audit-log/page.tsx`

**Done when:** Audit log viewer correctly shows only the logged-in org's rows; Manager/Cashier cannot reach this route even by URL.

**Build Day 16 — Wednesday, July 29, 2026 — Phase 1, Week 3, Day 4**
**Build:**
- End-to-end Playwright smoke test: signup → onboarding wizard → PIN login as cashier → logout → login as owner → see store
- Fix any RLS or route-guard gaps the E2E test surfaces

**Files/Tables touched:** `tests/e2e/phase1-smoke.spec.ts`

**Done when:** E2E smoke test passes in CI.

**Build Day 17 — Thursday, July 30, 2026 — Phase 1, Week 3, Day 5**
**Build:**
- Phase 1 close-out: demo the multi-tenant schema + Agency dashboard + all 4 role shells to the developer
- Freeze schema changes for Phase 1 scope — anything new discovered gets logged as a decision, not silently added
- Update `LottoGuard-MASTER.md` status table

**Files/Tables touched:** `LottoGuard-MASTER.md`

**Done when:** Developer signs off Phase 1 complete. Phase 2 can start.

---

## PHASE 2 — SCAN ENGINE + PJR BRIDGE (Weeks 4–5, Build Days 18–27, Jul 31 – Aug 13, 2026)

**Objective:** Barcode scan flow for packs/shifts, plus the PJR Bridge desktop app — moved up from Month 4+ per Decision 27, since it's now validated against real Gilbarco Passport data (Appendix A).

### Week 4 — Scan Engine

**Build Day 18 — Friday, July 31, 2026 — Phase 2, Week 4, Day 1**
**Build:**
- Integrate ZXing barcode scanner component (camera-based, web) into a reusable `<BarcodeScanner>` component
- Pack receive/activate flow (Sitemap page 15, Manager-facing): scan pack barcode → create `packs` row, status `active`

**Files/Tables touched:** `components/BarcodeScanner.tsx`, `packs` table writes

**Done when:** Scanning a real barcode (any UPC, test data fine here) creates a correctly-populated `packs` row.

**Build Day 19 — Monday, August 3, 2026 — Phase 2, Week 4, Day 2**
**Build:**
- Shift start scan flow (Sitemap page 7, Cashier): batch scan flow for multiple active packs, writes `shifts` row per pack with `ticket_start`
- Enforce: no manual number entry anywhere in this flow (hard rule, Decision 14 / Master Document Section 9)

**Files/Tables touched:** `app/(cashier)/shift-start/page.tsx`, `shifts` table

**Done when:** A cashier can scan 3+ packs at shift start in one batch flow with zero manual number fields present in the UI.

**Build Day 20 — Tuesday, August 4, 2026 — Phase 2, Week 4, Day 3**
**Build:**
- Shift end / closing scan + handover flow (Sitemap page 11): scan closing position, dual PIN sign-off (`going_signed_by` + `incoming_signed_by`)
- Mid-pack shift end handling: pack ownership passes to next shift cleanly (Master Document Section 9)

**Files/Tables touched:** `app/(cashier)/shift-end/page.tsx`, `shifts.ticket_end`, `shifts.going_signed_by`, `shifts.incoming_signed_by`

**Done when:** A full shift-start → shift-end cycle produces an immutable `shifts` row with correct start/end positions and both signatures.

**Build Day 21 — Wednesday, August 5, 2026 — Phase 2, Week 4, Day 4**
**Build:**
- Late-scan override request flow (Sitemap page 12, Manager-approved): logged reason, flagged permanently in the record
- Enforce `shifts` immutability after dual sign-off at the RLS/trigger level (no UPDATE allowed post-signoff, only append)

**Files/Tables touched:** `app/(cashier)/override-request/page.tsx`, `shifts` immutability trigger

**Done when:** Attempting to UPDATE a signed-off shift row fails at the database level, not just the UI level.

**Build Day 22 — Thursday, August 6, 2026 — Phase 2, Week 4, Day 5**
**Build:**
- Offline queue foundation (IndexedDB) for the scan flow — c-store WiFi is unreliable, this is non-negotiable per Master Document Section 9
- Sync-on-reconnect logic

**Files/Tables touched:** `lib/offline-queue.ts`

**Done when:** Turning off WiFi mid-scan-flow queues the scan locally; reconnecting syncs it to Supabase without data loss or duplication.

### Week 5 — PJR Bridge Desktop App

**Build Day 23 — Friday, August 7, 2026 — Phase 2, Week 5, Day 1**
**Build:**
- Scaffold Electron.js desktop app in a separate sub-project: `lottoguard/integrations/bridge-app/`
- Folder-watcher pointed at a configurable `XMLGateway\BOOutBox` path (per Appendix A findings)

**Files/Tables touched:** `integrations/bridge-app/` (new sub-project)

**Done when:** The Electron app detects a new file dropped into a local test folder within 5 seconds.

**Build Day 24 — Monday, August 10, 2026 — Phase 2, Week 5, Day 2**
**Build:**
- Write `pjr-parser.ts` against the three real sample PJR files already in hand (Appendix A) — parse TransactionID, CashierID, timestamps, ItemLine fields, TenderInfo, cancel/suspend flags
- Unit tests using the real sample files as fixtures

**Files/Tables touched:** `integrations/pjr-parser.ts`, `tests/unit/pjr-parser.test.ts`

**Done when:** All three real sample files parse into the correct internal transaction shape with 100% field accuracy, verified against the Appendix A schema table.

**Build Day 25 — Tuesday, August 11, 2026 — Phase 2, Week 5, Day 3**
**Build:**
- Universal internal transaction format (Appendix A, Section A.7, Layer 2): define the shared TypeScript type all POS translators output into
- Offline SQLite queue in the Bridge app (queues if internet is down)
- `sender.ts`: pushes parsed transactions to the LottoGuard API

**Files/Tables touched:** `integrations/queue.ts`, `integrations/sender.ts`, `lib/types/universal-transaction.ts`

**Done when:** A parsed PJR file reaches a real `tallies` row in Supabase end-to-end, including surviving a simulated internet outage.

**Build Day 26 — Wednesday, August 12, 2026 — Phase 2, Week 5, Day 4**
**Build:**
- Lottery MerchandiseCode filter — ⛔ **BLOCKED on Appendix A Section A.9 item 1** (real value not yet known). **Fallback for today:** build the filter as a configurable per-store value (`stores.lottery_merchandise_code`), leave it empty/null-safe, write the filter logic to no-op gracefully until the value is set
- Data source & POS connection status page (Sitemap page 27): shows Bridge app online/offline, last file received timestamp

**Files/Tables touched:** `stores.lottery_merchandise_code`, `app/(owner)/data-sources/page.tsx`

**Done when:** The status page correctly shows "Bridge connected, awaiting lottery code configuration" for the pilot store — honest incomplete state, not a fake green checkmark.

**Build Day 27 — Thursday, August 13, 2026 — Phase 2, Week 5, Day 5**
**Build:**
- Bridge app installer packaging (Sitemap page 45) + setup guide doc
- Phase 2 close-out demo: full scan flow + Bridge app pulling real PJR data into Supabase
- Update `LottoGuard-MASTER.md`

**Files/Tables touched:** `integrations/bridge-app/` installer config, `LottoGuard-MASTER.md`

**Done when:** Developer signs off Phase 2 complete. Note in the log: MerchandiseCode filter remains ⛔ blocked pending next store visit — does not block Phase 3 start.

---

## PHASE 3 — SPOT-CHECK SYSTEM (Weeks 6–7, Build Days 28–37, Aug 14 – Aug 27, 2026)

**Objective:** The core theft-deterrence mechanism — random spot-check generation, photo capture, AI/human review. Checkly added this phase (Decision 33) once there's real business logic to check.

### Week 6 — Selection Engine & Capture

**Build Day 28 — Friday, August 14, 2026 — Phase 3, Week 6, Day 1**
**Build:**
- Implement the Spot-Check Selection Algorithm exactly per Master Document Section 06: get active packs → calculate weight (ticket price, time since last check, prior anomalies, recently activated) → weighted random selection of N packs
- Runs on two triggers: SHIFT_START and SHIFT_END

**Files/Tables touched:** `lib/spot-check-engine.ts`, unit tests with seeded weight scenarios

**Done when:** Given a seeded set of packs with known weights, the algorithm's selection distribution matches expected probability within a statistical tolerance across 1000 simulated runs.

**Build Day 29 — Monday, August 17, 2026 — Phase 3, Week 6, Day 2**
**Build:**
- Random ticket number selection within the unsold range (between current scan position and end of pack) — only unsold tickets are callable
- `spot_checks` row creation with status `pending`

**Files/Tables touched:** `spot_checks` table writes

**Done when:** Requesting a spot-check never calls a ticket number that's already been sold, verified against `shifts.ticket_start`/`ticket_end` history.

**Build Day 30 — Tuesday, August 18, 2026 — Phase 3, Week 6, Day 3**
**Build:**
- Push notification to employee device on spot-check trigger; 10-minute completion window before escalation fires
- Add Checkly (Decision 33) — business logic check: spot-check generation actually fires on schedule

**Files/Tables touched:** `lib/notifications/push.ts`, Checkly config

**Done when:** A triggered spot-check reaches a test device notification within seconds; Checkly dashboard shows a green check for spot-check generation.

**Build Day 31 — Wednesday, August 19, 2026 — Phase 3, Week 6, Day 4**
**Build:**
- Spot-check camera capture screen (Sitemap page 9): in-app camera only, no gallery upload allowed
- Layer 1 client-side dual validation: readable barcode present + barcode matches requested ticket number, both must pass before upload

**Files/Tables touched:** `app/(cashier)/spot-check/page.tsx`

**Done when:** Attempting to upload a gallery photo is impossible at the OS permission/input level, not just discouraged in the UI; a barcode mismatch blocks submission client-side.

**Build Day 32 — Thursday, August 20, 2026 — Phase 3, Week 6, Day 5**
**Build:**
- Photo upload to Supabase Storage at path `{store_id}/{shift_id}/{ticket_number}.jpg`; `photo_metadata` JSONB captures lat/lng/timestamp/device_id/exif_present
- Spot-check confirmation screen (Sitemap page 10): hardcoded "Photo submitted successfully" regardless of outcome (Decision 12 — non-negotiable)

**Files/Tables touched:** Supabase Storage config, `spot_checks.photo_metadata`

**Done when:** A submitted photo lands in Storage at the correct path with full metadata; the confirmation screen shows the same message whether the photo will later pass or fail review — verified by code review, not just testing the happy path.

### Week 7 — AI Analysis & Review Queue

**Build Day 33 — Friday, August 21, 2026 — Phase 3, Week 7, Day 1**
**Build:**
- Layer 2 AI analysis (async, server-side): integrate Claude Vision or Google Vision API — checks scratch surface intact, ticket in book/pack (not held alone), physically undamaged, photo clarity
- Returns JSON confidence score per check

**Files/Tables touched:** `lib/ai/photo-analysis.ts`, Supabase Edge Function

**Done when:** A submitted photo triggers an async AI analysis job that returns a structured confidence score within the existing 10-minute window.

**Build Day 34 — Monday, August 24, 2026 — Phase 3, Week 7, Day 2**
**Build:**
- Confidence thresholds exactly per Master Document Decision 12: 85–100% + all pass = auto-pass; 85–100% + any fail = flag; 60–84% = flag; below 60% = flag. Thresholds configurable per agency org.

**Files/Tables touched:** `spot_checks.ai_confidence`, `spot_checks.status` (auto-passed / flagged)

**Done when:** Seeded test photos at each threshold band produce the correct auto-pass/flag outcome.

**Build Day 35 — Tuesday, August 25, 2026 — Phase 3, Week 7, Day 3**
**Build:**
- Layer 3 human review queue (Sitemap page 14, Manager-facing): flagged photos route here; Manager can approve or escalate
- Owner always sees all outcomes including manager approvals (Decision 12)

**Files/Tables touched:** `app/(manager)/spot-check-review/page.tsx`, `spot_checks.reviewed_by`, `spot_checks.review_outcome`

**Done when:** A flagged photo appears in the Manager queue; approving it correctly surfaces in the Owner's full outcome view too.

**Build Day 36 — Wednesday, August 26, 2026 — Phase 3, Week 7, Day 4**
**Build:**
- Silent owner alert dispatch on flag (real-time, per the silent-alerting requirement from the POS Integration doc): alerts go to Manager personal device + Owner personal phone only — the shared counter device NEVER receives flag alerts (Decision 12, hardcoded)
- Spot-check trigger configuration page (Sitemap page 28): all trigger options (shift sign-in/off, random N times per shift, fixed times, agency manual trigger)

**Files/Tables touched:** `lib/alerts/dispatch.ts`, `app/(owner)/spot-check-config/page.tsx`

**Done when:** Triggering a flag on a shared/kiosk-mode test device produces zero visible alert on that device, while the Manager's and Owner's personal test devices both receive it.

**Build Day 37 — Thursday, August 27, 2026 — Phase 3, Week 7, Day 5**
**Build:**
- E2E Playwright test: full spot-check cycle — trigger → capture → AI analysis → flag → manager review → owner visibility, plus the cashier-blind-to-outcome assertion
- Phase 3 close-out demo, update `LottoGuard-MASTER.md`

**Files/Tables touched:** `tests/e2e/spot-check-cycle.spec.ts`, `LottoGuard-MASTER.md`

**Done when:** Developer signs off Phase 3 complete.

---

## PHASE 4 — TALLY & RECONCILIATION (Weeks 8–9, Build Days 38–47, Aug 28 – Sep 10, 2026)

**Objective:** Cross-checking register/state data against scan logs. LSP scraper is ⛔ **blocked on Decision 28 credentials** — build everything else first, slot LSP in when credentials arrive.

### Week 8 — Manual & File-Based Entry

**Build Day 38 — Friday, August 28, 2026 — Phase 4, Week 8, Day 1**
**Build:**
- Manual tally entry screen (Sitemap page 16/26), enforcing the exact permission matrix from Section 2: Cashier never, Manager only if granted (with mandatory reason field + immediate owner notification), Owner/Agency always allowed
- Every manual entry sets `is_authoritative = false` permanently (Master Document Decision 14/22)

**Files/Tables touched:** `tallies` table, `app/(owner)/tally-entry/page.tsx`, `app/(manager)/tally-entry/page.tsx`

**Done when:** A Manager without explicit grant cannot reach this screen even by URL; a granted Manager's entry fires an immediate owner notification and sits in a review queue.

**Build Day 39 — Monday, August 31, 2026 — Phase 4, Week 8, Day 2**
**Build:**
- CSV upload path (universal fallback, Decision 24 Priority 5): manager exports from any POS, uploads file, parser extracts whatever the export contains
- `tallies.source` enum: manual/csv/email/pjr/zapier/lsp

**Files/Tables touched:** `lib/csv-parser.ts`, `tallies.source`

**Done when:** A sample CSV export uploads and produces correctly-tagged `tallies` rows with `source = 'csv'`.

**Build Day 40 — Tuesday, September 1, 2026 — Phase 4, Week 8, Day 3**
**Build:**
- Email inbound parser scaffold (Postmark/SendGrid webhook) — Decision 24 Priority 4. Full feature is Phase 7 per original scope, but the receiving webhook endpoint is cheap to stand up now alongside the other ingestion paths
- PJR tallies wired: Bridge app data (Phase 2) now flows into `tallies` with `source = 'pjr'`

**Files/Tables touched:** `app/api/webhooks/email-inbound/route.ts`, `tallies` PJR integration

**Done when:** PJR data from the Phase 2 Bridge app correctly populates `tallies` rows visible in the reconciliation view.

**Build Day 41 — Wednesday, September 2, 2026 — Phase 4, Week 8, Day 4**
**Build:**
- ⛔ **LSP scraper — check Decision 28 status first.** If credentials are in hand: build the nightly Vercel Cron job (LSP login + XML download + parse). If not: build the job scaffold and parser against the LSP XML format description in Decision 23, stub the login step, and flag clearly in `LottoGuard-MASTER.md` that this is running against unverified assumptions until real credentials arrive.

**Files/Tables touched:** `integrations/lsp-scraper/`

**Done when:** Either (a) a real nightly LSP pull succeeds against the pilot store's account, or (b) the scaffold is complete and clearly marked pending in the ops tracker — ask the developer which state applies before marking this day done.

**Build Day 42 — Thursday, September 3, 2026 — Phase 4, Week 8, Day 5**
**Build:**
- Reconciliation / tally view (Sitemap page 26): unify manual, CSV, Bridge/PJR, and LSP status into one screen per store
- Data source priority display: show which source is authoritative per Decision 24's priority table

**Files/Tables touched:** `app/(owner)/reconciliation/page.tsx`

**Done when:** The pilot store's reconciliation view correctly shows PJR as its highest-priority active source and manual entry (if any) clearly flagged as non-authoritative.

### Week 9 — Cross-Check Logic

**Build Day 43 — Friday, September 4, 2026 — Phase 4, Week 9, Day 1**
**Build:**
- Automatic tally cross-check granularity logic (Master Document Decision 15): system detects source quality, applies deepest possible comparison automatically — PJR enables per-game-per-shift-window comparison, CSV/manual only enables store-day or per-game-day

**Files/Tables touched:** `lib/cross-check-engine.ts`

**Done when:** Feeding the engine PJR-quality data produces shift-level gap attribution; feeding it CSV-quality data correctly falls back to day-level comparison without erroring.

**Build Day 44 — Monday, September 7, 2026 — Phase 4, Week 9, Day 2**
**Build:**
- Gap attribution to shift and employee: register/state tells totals, LottoGuard's own scan log narrows down which shift (Master Document Decision 15)
- Cross-validation logic when 2+ sources agree (Master Document Decision 24 "Cross-Validation" concept) — confidence scoring on alerts

**Files/Tables touched:** `lib/gap-attribution.ts`, `spot_checks`/`tallies` join logic

**Done when:** A seeded gap scenario (known missing tickets) correctly attributes to the right shift/employee, and a two-source-agreement scenario produces a "VERY HIGH confidence" flagged alert.

**Build Day 45 — Tuesday, September 8, 2026 — Phase 4, Week 9, Day 3**
**Build:**
- Confidence tier auto-detection wired to real store status (Decision 31): a store's `confidence_tier` field updates automatically as data sources come online, never manually set

**Files/Tables touched:** `stores.confidence_tier` trigger/Edge Function

**Done when:** Adding a working LSP connection to a test store automatically upgrades its tier without any manual UI action available to do so.

**Build Day 46 — Wednesday, September 9, 2026 — Phase 4, Week 9, Day 4**
**Build:**
- Integration tests: `tests/integration/api/tallies.test.ts` — manual entry, CSV, cross-check logic, gap attribution
- Fix any RLS gaps around the new `tallies`/cross-check tables

**Files/Tables touched:** `tests/integration/api/tallies.test.ts`

**Done when:** CI green on full Phase 4 suite.

**Build Day 47 — Thursday, September 10, 2026 — Phase 4, Week 9, Day 5**
**Build:**
- Phase 4 close-out demo: reconciliation view + cross-check engine against real pilot store PJR data
- Update `LottoGuard-MASTER.md`, confirm LSP credential status with developer

**Files/Tables touched:** `LottoGuard-MASTER.md`

**Done when:** Developer signs off Phase 4 complete.

---

## PHASE 5 — DASHBOARDS & ALERTS (Weeks 10–11, Build Days 48–57, Sep 11 – Sep 24, 2026)

**Objective:** Owner dashboard, network dashboard, cross-store employee pattern detection (moved up from Phase 7 — Decision 34), SMS/push, risk scoring, complaints.

### Week 10 — Dashboards & Risk Scoring

**Build Day 48 — Friday, September 11, 2026 — Phase 5, Week 10, Day 1**
**Build:**
- Owner single-store dashboard (Sitemap page 20): active packs, current ticket positions, shift status at a glance
- Real-time alert feed (Sitemap page 21) using Supabase Realtime

**Files/Tables touched:** `app/(owner)/dashboard/page.tsx`, Supabase Realtime subscription

**Done when:** A spot-check flag fired from a test device appears in the Owner's alert feed within 2 seconds, no page refresh needed.

**Build Day 49 — Monday, September 14, 2026 — Phase 5, Week 10, Day 2**
**Build:**
- Employee risk score calculation: Supabase Edge Function triggered on anomaly events, updates `employees.risk_score` (Master Document Section 05)
- Employee management page (Sitemap page 23): add/remove/deactivate, risk score detail view

**Files/Tables touched:** `employees.risk_score`, Edge Function trigger, `app/(owner)/employees/page.tsx`

**Done when:** A seeded pattern of repeated anomalies on one employee visibly moves their risk score; deactivation revokes access immediately while historical records remain permanent (Master Document Section 9).

**Build Day 50 — Tuesday, September 15, 2026 — Phase 5, Week 10, Day 3**
**Build:**
- Twilio SMS integration + web push notifications for real-time alerts
- Notification preferences wired to actually send (schema existed since Phase 1 Day 15, now functional)

**Files/Tables touched:** `lib/notifications/sms.ts`, `lib/notifications/push.ts` (activate)

**Done when:** A test alert reaches both SMS and push channels for a seeded Owner account within the same 2-second window as the in-app alert.

**Build Day 51 — Wednesday, September 16, 2026 — Phase 5, Week 10, Day 4**
**Build:**
- Network dashboard (Sitemap page 30): all stores for a multi-store Owner in one view — data model has existed since Phase 1 (Decision 32), this is the UI layer
- Store comparison view (Sitemap page 32): ranked by anomaly frequency

**Files/Tables touched:** `app/(owner)/network/page.tsx`

**Done when:** A seeded Owner with 3 stores sees all three correctly ranked by anomaly count with zero cross-store data leakage to any other Owner.

**Build Day 52 — Thursday, September 17, 2026 — Phase 5, Week 10, Day 5**
**Build:**
- Cross-store employee pattern detection (Sitemap page 31, Decision 34): same employee flagged across multiple locations under one chain
- Analytics query surfaces repeat employee-pair or employee-location anomaly patterns

**Files/Tables touched:** `lib/cross-store-patterns.ts`

**Done when:** A seeded employee working at 2 stores under the same Owner with anomalies at both correctly surfaces as a cross-store pattern; an employee at 2 *different* owners' stores does not incorrectly correlate (org isolation still holds).

### Week 11 — Complaints & Network Polish

**Build Day 53 — Friday, September 18, 2026 — Phase 5, Week 11, Day 1**
**Build:**
- Complaint intake form (Sitemap page 19, Manager) + complaint trace tool (Sitemap page 24, Owner): ticket serial → shift ownership in one query

**Files/Tables touched:** `complaints` table, `app/(manager)/complaints/page.tsx`, `app/(owner)/complaint-trace/page.tsx`

**Done when:** Entering a ticket serial in the trace tool returns the exact shift, employee, and any spot-check photo evidence for that ticket within one query.

**Build Day 54 — Monday, September 21, 2026 — Phase 5, Week 11, Day 2**
**Build:**
- Incident report generator (Sitemap page 25): one-tap PDF export — weight log, scan log, shift ownership, tally mismatch, employee history, photos
- Network-wide reconciliation export (Sitemap page 33)

**Files/Tables touched:** `lib/reports/incident-pdf.ts`, `app/(owner)/incident-report/page.tsx`

**Done when:** A generated incident report PDF contains every listed data category for a seeded flagged scenario, ready to hand to HR/legal/insurance.

**Build Day 55 — Tuesday, September 22, 2026 — Phase 5, Week 11, Day 3**
**Build:**
- Agency manual spot-check trigger (Sitemap page 36, Decision 13): any store, any pack, any employee, any time, source never revealed to cashier
- Org-wide config bounds editor (Sitemap page 37): Agency sets min/max spot-check ranges

**Files/Tables touched:** `app/(agency)/manual-trigger/page.tsx`, `app/(agency)/config-bounds/page.tsx`

**Done when:** An Agency-triggered spot-check reaches the cashier device identically to an automated one — no distinguishing marker anywhere in the cashier-facing UI.

**Build Day 56 — Wednesday, September 23, 2026 — Phase 5, Week 11, Day 4**
**Build:**
- Data source assignment page (Sitemap page 38): Agency assigns integration path per store
- Multi-store billing management (Sitemap page 34): per-store fee rollup

**Files/Tables touched:** `app/(agency)/data-source-assignment/page.tsx`, billing rollup logic (Stripe, standalone module)

**Done when:** Changing a store's assigned data source path from the Agency view correctly updates that store's config profile without touching billing logic (module boundary intact, per the existing billing build rule).

**Build Day 57 — Thursday, September 24, 2026 — Phase 5, Week 11, Day 5**
**Build:**
- Phase 5 close-out demo: full dashboard suite, cross-store patterns, complaint trace, incident reports
- Update `LottoGuard-MASTER.md`

**Files/Tables touched:** `LottoGuard-MASTER.md`

**Done when:** Developer signs off Phase 5 complete.

---

## PHASE 6 — POLISH & PILOT LAUNCH (Weeks 12–13, Build Days 58–67, Sep 25 – Oct 8, 2026)

**Objective:** Office Staff role (moved up — Decision 35), onboarding wizard polish, mobile audit, offline-mode hardening, Better Uptime (Decision 33), pilot store goes live.

### Week 12 — Office Staff Role & Onboarding Polish

**Build Day 58 — Friday, September 25, 2026 — Phase 6, Week 12, Day 1**
**Build:**
- Office Staff role (Decision 35): read-only reconciliation dashboard (Sitemap page 40), scoped by explicit grant
- RLS policies: strictly SELECT-only, no acknowledgment/dismissal rights anywhere

**Files/Tables touched:** `employees.role` enum extension, `app/(office-staff)/dashboard/page.tsx`, RLS

**Done when:** A seeded Office Staff account can view but cannot mutate any row in any table, verified by attempting every write operation and confirming rejection.

**Build Day 59 — Monday, September 28, 2026 — Phase 6, Week 12, Day 2**
**Build:**
- Report export (Sitemap page 41) + anomaly feed view-only (Sitemap page 42) for Office Staff

**Files/Tables touched:** `app/(office-staff)/export/page.tsx`, `app/(office-staff)/anomalies/page.tsx`

**Done when:** Office Staff export produces the same PDF/CSV Owner would see, with no edit affordances present.

**Build Day 60 — Tuesday, September 29, 2026 — Phase 6, Week 12, Day 3**
**Build:**
- Onboarding wizard full polish (Sitemap page 4): guided first-use flow answering "who enters employees, who scans the first pack" (Master Document Section 9)
- Employee turnover flow polish: easy add/remove, immediate deactivation

**Files/Tables touched:** `app/(owner)/onboarding/page.tsx` (polish pass)

**Done when:** A first-time Owner with zero prior context can complete setup unassisted in a usability test.

**Build Day 61 — Wednesday, September 30, 2026 — Phase 6, Week 12, Day 4**
**Build:**
- Mobile responsiveness audit across all Cashier + Manager screens (these are the shared-tablet/phone-heavy roles)
- Multiple active packs batch handling polish (8–10 packs, per Master Document Section 9)

**Files/Tables touched:** CSS/layout passes across `app/(cashier)/`, `app/(manager)/`

**Done when:** Every Cashier/Manager screen is fully usable at common phone/tablet viewport sizes with no horizontal scroll or clipped controls.

**Build Day 62 — Thursday, October 1, 2026 — Phase 6, Week 12, Day 5**
**Build:**
- Offline-mode hardening: full audit of every write path for offline queue coverage, not just the shift scan flow from Phase 2
- Photo storage retention policy implementation (90 days passed checks, indefinite for failed/flagged — Master Document Section 9)

**Files/Tables touched:** `lib/offline-queue.ts` (extend coverage), Supabase Storage lifecycle rules

**Done when:** Every write-capable screen survives a simulated offline/reconnect cycle without data loss.

### Week 13 — Launch Readiness

**Build Day 63 — Friday, October 2, 2026 — Phase 6, Week 13, Day 1**
**Build:**
- Create staging Supabase project (Decision 41 — deliberately deferred from Phase 0 to right before launch, since there's no production traffic to protect until now); wire the "always migrate to staging before production" rule (Ops Tracker Section 14) into the deploy process, covering the multi-tenant tables from Phase 1 onward, not just later feature tables
- Add Better Uptime (Decision 33) — production uptime monitoring, right before real launch
- Wire dual outage escalation (Decision 39): Better Uptime triggers both (a) a live status banner on the Data Source & POS Connection Status page (Sitemap page 27, built Phase 2 Day 26) and (b) a direct SMS/call page to Farheen — same event, two channels, no silent failures
- Full security pass: confirm every RLS policy against the Section 2 access matrix, one final audit

**Files/Tables touched:** new staging Supabase project, deploy pipeline config, Better Uptime config + alert integration, `app/(owner)/data-sources/page.tsx` (status banner), RLS audit checklist

**Done when:** A test migration correctly hits staging before production; a simulated Bridge outage produces both the owner-facing banner and a real page to Farheen within seconds of each other; RLS audit checklist fully checked off against the access matrix with no gaps.

**Build Day 64 — Monday, October 5, 2026 — Phase 6, Week 13, Day 2**
**Build:**
- ⛔ **Check Appendix A Section A.9 blocked items status with developer.** If the pilot store visit has happened: wire the real lottery MerchandiseCode (Day 26's deferred filter) and confirm barcode-uniqueness handling in the parser. If not: this remains the single most important pre-launch gap — flag loudly, do not launch silently degraded without the developer's explicit sign-off.

**Files/Tables touched:** `stores.lottery_merchandise_code` (real value), `pjr-parser.ts` (finalize)

**Done when:** Either the pilot store's lottery filter is fully live, or the developer has explicitly acknowledged launching without it.

**Build Day 65 — Tuesday, October 6, 2026 — Phase 6, Week 13, Day 3**
**Build:**
- Full E2E Playwright regression across all 6 phases' critical paths
- Load-test the spot-check engine and alert dispatch under a simulated multi-store, multi-shift load

**Files/Tables touched:** `tests/e2e/full-regression.spec.ts`

**Done when:** CI green across the entire E2E suite; alert dispatch stays under the required latency under simulated load.

**Build Day 66 — Wednesday, October 7, 2026 — Phase 6, Week 13, Day 4**
**Build:**
- Pilot store live onboarding: real Owner account, real employees, real packs, Bridge app installed on the real back-office PC
- Shadow-mode monitoring for the first live shift (developer watches closely, no customer-facing claims made yet)

**Files/Tables touched:** production data, not code

**Done when:** One full real shift completes end-to-end on the live pilot store with no critical errors in Sentry.

**Build Day 67 — Thursday, October 8, 2026 — Phase 6, Week 13, Day 5**
**Build:**
- Pilot launch retrospective: what broke, what surprised, what Phase 7 priorities shift based on real usage
- Update `LottoGuard-MASTER.md` to reflect live status; freeze Phase 1–6 scope

**Files/Tables touched:** `LottoGuard-MASTER.md`

**Done when:** Developer signs off — LottoGuard is live at the pilot store. Phase 7 planning begins.

---

---

## MANUAL SUPPORT PROCESSES (Documented, Not Built)

Not every decision needs code. This is deliberately outside the day sequence — it's a process for Farheen to follow personally, not a feature to build.

**Data export on cancellation (Decision 38):** When an owner cancels, there is no self-serve export button. The owner emails Farheen directly; she exports their data manually and confirms delivery before revoking access. Revisit as an automated self-serve flow once support volume makes manual handling impractical — not before. If this process is invoked for the pilot store or any early customer, log it in `LottoGuard-MASTER.md` so there's a record of how often it's actually happening.

---

## PHASE 7 — REMAINING ENHANCEMENTS (Starts Oct 9, 2026)

**Not broken into days** — this phase starts only after real pilot usage data exists to prioritize against. Week-level buckets below are a starting proposal, to be re-ordered based on what the pilot store actually surfaces as most valuable.

- **Week 1:** Email inbound parser (finish the Phase 4 Day 40 webhook scaffold into a full nightly auto-parse)
- **Week 2:** PDF incident report refinements based on real pilot usage feedback
- **Week 3–4:** AI photo analysis accuracy tuning against real accumulated spot-check photo data (more training signal than existed at Phase 3 build time)
- **Week 5–6:** Trend & pattern analytics (stores/games/shifts/days/seasons anomaly analysis)
- **Week 7:** Zapier webhook receiver for modern back-office platforms
- **Ongoing:** Second pilot store onboarding (Verifone or a different Gilbarco config) — validates the multi-POS translator architecture (Appendix A, Section A.7, Layer 2) against a second real brand

---

*End of day-by-day build plan. Re-generate or amend this file — do not let it silently drift from LottoGuard_Build_Execution_Plan.docx v1.1. If a phase's scope changes there, this file needs a matching update.*
