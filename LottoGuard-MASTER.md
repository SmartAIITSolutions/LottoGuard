# LottoGuard — Session Start Reference
### Read this at the start of every build session before writing any code.

**Last updated:** July 8, 2026 (Build Day 2 complete)
**Repo:** https://github.com/SmartAIITSolutions/LottoGuard
**Target pilot launch:** Thursday, October 8, 2026 (Build Day 67)

---

## Current Status

| Item | Status |
|------|--------|
| Current phase | Phase 0 — Ops Setup |
| Current build day | Day 2 complete — Day 3 next (Phase 1 starts) |
| `npm run dev` passing | ✅ |
| CI (typecheck + build) | ✅ |
| Semgrep scan | ✅ |
| Dependabot | ✅ |
| Supabase project | ✅ Created (US East, dedicated) |
| Vercel project | ✅ Linked to repo, deployed |
| Branch protection on `main` | ✅ |
| Linear board | ⏸ Deferred — revisit before second customer |

---

## Phase Progress

| Phase | Name | Days | Status |
|-------|------|------|--------|
| 0 | Ops Setup | 1–2 | ✅ Complete |
| 1 | Foundation | 3–17 | 🔲 Not started |
| 2 | Scan Engine + PJR Bridge | 18–27 | 🔲 Not started |
| 3 | Spot-Check System | 28–37 | 🔲 Not started |
| 4 | Tally & Reconciliation | 38–47 | 🔲 Not started |
| 5 | Dashboards & Alerts | 48–57 | 🔲 Not started |
| 6 | Polish & Pilot Launch | 58–67 | 🔲 Not started |

---

## Blocked Items (Do Not Build Around Without Developer Sign-Off)

| # | Item | Blocked on | First needed |
|---|------|-----------|--------------|
| B1 | Lottery MerchandiseCode filter | Real value from pilot store visit | Build Day 26 |
| B2 | Barcode uniqueness (ticket-unique vs generic tag) | Observation at register during live sale | Build Day 26 / 64 |
| B3 | LSP portal credentials | Owner login access to state lottery back-office | Build Day 41 |

---

## Pending Decisions

None open at this time. All decisions through Decision 41 are logged in `LottoGuard_CONSOLIDATED_MASTER.docx`.

---

## Engineering Rules (Non-Negotiable — Section 12 & 13)

- `npx tsc --noEmit` must pass before any PR is opened
- No `any` type anywhere — ever
- No manual number entry in any scan flow — ever
- No secrets or hardcoded values in code — ever
- No code without developer discussion and explicit permission first
- No pushing directly to `main` — all changes via PR
- Migration before code — every schema change starts as a SQL file
- RLS written at same time as the table — never added later

---

## Key Decisions Quick Reference

| Decision | What it means |
|----------|--------------|
| 12 | Cashier always sees "Photo submitted successfully" regardless of outcome — hardcoded, no exceptions |
| 13 | Agency can trigger a spot-check on any store/pack/employee at any time — source never revealed to cashier |
| 14 | No manual number entry anywhere in the scan flow — closing number from physical scan only |
| 24 | PJR Direct Bridge is highest-validated integration path — Priority 3 in data source table |
| 31 | Confidence tier auto-detected from data sources — never manually set via UI |
| 32 | Multi-tenant from day one: Agency → Owner → many Stores |
| 33 | No Doppler. Sentry added Day 7. Checkly added Day 30. Better Uptime added Day 63. |
| 37 | Owner consent checkbox required before onboarding wizard completes |
| 38 | Data export on cancellation is manual — owner emails Farheen, no self-serve button yet |
| 39 | Dual outage escalation: status banner on UI + direct SMS/call to Farheen |
| 41 | Staging Supabase project created Day 63 (right before launch), not Phase 0 |

---

## Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Next.js 14 + TypeScript (strict) |
| Database | Supabase (Postgres + Auth + Storage + Realtime + Edge Functions) |
| Hosting | Vercel |
| Payments | Stripe (billing only — separate module) |
| SMS | Twilio |
| Barcode scanning | @zxing/browser |
| Desktop bridge | Electron.js (Phase 2) |
| AI photo analysis | Claude Vision API (Phase 3) |

---

## Repo Structure (Target — enforced from Phase 1)

```
app/(auth)/          Login, register, password reset
app/(agency)/        Agency-only routes
app/(owner)/         Owner-only routes
app/(manager)/       Manager-only routes
app/(cashier)/       Cashier-only routes
app/api/             All API routes
components/ui/       Generic reusable components only — no business logic
components/{feature}/Feature-specific components
lib/supabase/        client.ts, server.ts, admin.ts — nowhere else
lib/parsers/         Pure functions: barcode, csv, email, pjr parsers
lib/algorithms/      Pure business logic: spot-check engine, risk score
lib/constants.ts     All string constants, enums, thresholds
hooks/               Custom React hooks only
types/               All TypeScript types
supabase/migrations/ Every schema change as a numbered SQL migration
supabase/functions/  Edge Functions
tests/               unit/, integration/, e2e/
```
