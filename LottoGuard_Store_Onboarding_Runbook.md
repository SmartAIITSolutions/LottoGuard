# 🏪 LottoGuard — Store Onboarding Runbook (Technical / Data Access)
### Turns the July 7–8, 2026 pilot store investigation into a repeatable checklist

> **Who this is for:** Whoever is physically on-site connecting a new store's POS to LottoGuard — Farheen for roughly the first 3–5 Gilbarco stores, then handed to remote screen-share support once it stops being exploratory. Not for the in-app software setup (that's the Phase 1 onboarding wizard, Sitemap page 4) — this is purely "how do we get real transaction data out of this store's register."

**Source:** Every step below comes from the real pilot store visit (Appendix A, LottoGuard_CONSOLIDATED_MASTER.docx). Nothing here is theoretical — it's what actually worked, in the order it actually happened.

**Estimated time:** 1–2 hours for a known-good Gilbarco Passport store once you've done this a few times. The pilot visit took longer because it was also R&D — that cost doesn't repeat.

---

## Before You Go

- [ ] Confirm the POS brand with the store owner/manager ahead of time if at all possible (ask: "what's on the register screen or printed on the receipt — Passport, Commander, Ruby, or something else?")
- [ ] If it's **Gilbarco Passport** → this runbook applies directly, proceed below.
- [ ] If it's **Verifone, NCR, or anything else** → this is a new R&D trip, not a repeatable checklist yet. Budget it like the original pilot visit, not like a quick install. (See "When the Brand Is Different" at the bottom.)
- [ ] Confirm you'll have someone on-site who can grant login access to the back-office PC (owner, manager, or whoever administers it)
- [ ] Bring: laptop, this checklist, a way to photograph/screenshot the screen as you go (paper trail matters if something needs debugging later)

---

## On-Site Steps

### 1. Identify the exact POS setup
- [ ] Confirm brand + software version (Manager Workstation → About/Settings screen, or ask whoever services it). Pilot store was Gilbarco Passport **24.04.23.01MP23** — note the exact version string, don't approximate.
- [ ] Ask: **"Is there a back-office computer here — a PC in the office that connects to the register system?"** You need that PC, not the register terminal itself.

### 2. Get access to the back-office PC
- [ ] Get a login (or have someone log in for you) directly on that PC
- [ ] Open File Explorer → look for a **network drive or mapped share** related to the POS. Pilot store had it as `XMLGateway (\\10.5.48.2) (Z:)` under Network locations / mapped drives — the exact IP/drive letter will differ per store, the pattern (a network share named something like XMLGateway) should not.

### 3. Find the transaction data folder
- [ ] Inside that share, look for a folder named **`BOOutBox`** — this is the live transaction feed. Confirmed folder siblings to expect: `ArchiveDir`, `Processed`, `BOInBox` (incoming only, not your target), `FuelPriceManagement`, `PriceBookExport`, `Wetstock` (not relevant), `AuditLogs`, `DeadLetter`.
- [ ] Open `BOOutBox`. You're looking for files prefixed **`PJR`** — these are POS Journal Reports, one file per transaction. Other prefixes you'll see and can ignore: `ISM`, `MCM`, `MSM`, `FGM`, `FPM`, `TLM`, `TPM` (all summary/movement files, not transaction detail).
- [ ] Confirm PJR files have recent timestamps close to real-time (pilot store generated roughly one every 1–6 minutes during an active shift). If `BOOutBox` is empty or stale, ask the manager whether the store is mid-shift — files generate as sales happen.

### 4. Capture real sample files
- [ ] Copy at least 3–5 PJR files covering a mix: a normal sale, a void/cancelled transaction if you can catch one, and ideally one that includes a lottery ticket line item
- [ ] Open one in Notepad (right-click → Open with → Notepad — do not double-click, it may try to launch elsewhere) to sanity-check it starts with `<?xml version="1.0"?>` and `<NAXML-POSJournal`

### 5. Confirm the store's lottery configuration
- [ ] Ask the manager directly: **"How does lottery get rung up at the register — is it scanned, or typed in manually?"**
- [ ] Ask: **"Is lottery its own department/category, or lumped in with general merchandise?"**
- [ ] If scanned as its own PLU/department (as the pilot store does): find a PJR file from an actual lottery sale (watch the register, note the time, find the matching file) and record:
  - [ ] The `MerchandiseCode` value used for lottery line items
  - [ ] Whether the `POSCode` (barcode) is **ticket-unique** or a **generic per-game tag** — test this by watching two different tickets of the *same* game sell, and comparing their `POSCode` values. Identical = generic tag. Different = ticket-unique serial. This single fact determines how strong the theft-detection correlation can be at this store (see Appendix A, Section A.7 confidence tiers) — do not skip this test.
- [ ] Ask whether scratch-offs and draw games (Powerball-style) are scanned the same way or use different codes

### 6. Confirm the lottery terminal situation
- [ ] Ask: **"Is there a separate state lottery terminal here, independent of the register?"**
- [ ] If yes: ask who manages it and how sales/activation reports get pulled from it (screen report, file export, etc.) — this is the second data source needed for correlation, separate from the PJR/register side
- [ ] Ask the owner to log into their **LSP portal** (state lottery back-office) while you're there if at all possible — get real credentials or confirm access exists. This is Decision 28's blocker; closing it out on the same visit saves a return trip.

### 7. Install the Bridge app (once Phase 2 build is ready)
- [ ] Run the LottoGuard Bridge installer on the back-office PC
- [ ] Point it at the confirmed `BOOutBox` path from Step 3
- [ ] Confirm on your end (via the Data Source & POS Connection Status page, Sitemap page 27) that files are being received in real time
- [ ] Enter the confirmed `MerchandiseCode` from Step 5 into the store's config profile

### 8. Fill in the store config profile
Record all of this in the store's config profile (Appendix A, Section A.7, Layer 1) before you leave:
- [ ] POS brand & exact version
- [ ] Network/file access path (the XMLGateway share address)
- [ ] Lottery entry method (scanned dedicated PLU / manual / mixed)
- [ ] Lottery MerchandiseCode(s)
- [ ] Ticket barcode uniqueness (ticket-unique / generic tag)
- [ ] Separate lottery terminal present? (yes/no + LSP access status)
- [ ] Resulting confidence tier (this should now be automatic per Decision 31 — verify it, don't override it manually)

---

## After You Leave

- [ ] Back up the captured sample PJR files somewhere durable — they're useful reference even after the store is live
- [ ] If anything didn't match this runbook (a folder wasn't where expected, a prefix was different, the share was structured differently), update this document immediately, not "later" — the whole point is that the next visit gets easier, not that you re-discover the same things twice
- [ ] Update `LottoGuard-MASTER.md` with the new store's status

---

## When The Brand Is Different (Verifone, NCR, etc.)

This runbook does not apply yet. Treat it like the original pilot visit:
- Expect to spend real time finding the equivalent of `XMLGateway`/`BOOutBox` for that brand
- Expect the file format and naming convention to be different (do not assume `PJR` prefixes or NAXML structure carries over)
- Once you've done it once successfully, write a parallel runbook (`LottoGuard_Store_Onboarding_Runbook_Verifone.md`) the same way this one was written from the Gilbarco visit
- This is expected, planned work — it's Phase 7's "second pilot store, validates the multi-POS translator architecture" item, not a sign anything went wrong

---

*This runbook should get shorter and more confident with each Gilbarco store, not longer. If a visit takes as long as the original pilot did, something about the checklist isn't capturing the real pattern yet — fix the runbook, don't just push through it.*
