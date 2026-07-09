-- ============================================================
-- Migration 002 — employees
-- LottoGuard employee table with dual auth model:
--   - Owner/Manager/Agency: Supabase Auth (auth_user_id set)
--   - Cashier (shared tablet): PIN login only (auth_user_id null)
-- ============================================================

-- ============================================================
-- TABLE: employees
-- All store-level users: owners, managers, cashiers, office staff
-- ============================================================
CREATE TABLE employees (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id                  UUID NOT NULL REFERENCES stores (id) ON DELETE RESTRICT,

  -- Supabase Auth link — set for Owner/Manager/Agency, NULL for Cashiers
  -- Cashiers use PIN login only (shared tablet flow)
  auth_user_id              UUID REFERENCES auth.users (id) ON DELETE SET NULL,

  name                      TEXT NOT NULL,

  -- Role enum — drives all RLS policies and route access (Day 5 + Day 8)
  role                      TEXT NOT NULL CHECK (
                              role IN ('owner', 'manager', 'cashier', 'office_staff')
                            ),

  -- PIN hash — used for shared-tablet device login (cashier + manager)
  -- Stored as bcrypt hash — never store raw PINs
  -- NULL for users who only ever use Supabase Auth (e.g. Agency-level users)
  pin_hash                  TEXT,

  -- Risk score — calculated by Edge Function on anomaly events (Day 49)
  -- Composite of: spot-check fails, tally mismatches, complaint traces, serial gaps
  risk_score                INTEGER NOT NULL DEFAULT 0,

  -- Decision 37: employee sees a consent interstitial on their very first PIN login
  -- NULL = consent not yet acknowledged. Set to timestamp on first acknowledgment.
  -- Once set, the interstitial never shows again for this employee.
  consent_acknowledged_at   TIMESTAMPTZ,

  -- Deactivation revokes access immediately — historical records remain forever
  active                    BOOLEAN NOT NULL DEFAULT TRUE,

  created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index: most common query — all employees for a given store
CREATE INDEX idx_employees_store_id ON employees (store_id);

-- Index: auth lookup — map Supabase Auth session back to employee record
CREATE INDEX idx_employees_auth_user_id ON employees (auth_user_id);

-- Index: role filtering per store (used by RLS policies and dashboards)
CREATE INDEX idx_employees_store_role ON employees (store_id, role);

-- ============================================================
-- RLS
-- Enabled now. Full user-facing policies added Day 5
-- once the complete auth system and role hierarchy is in place.
-- Until then: service role only.
-- ============================================================
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;

-- Service role has full access (Edge Functions, migrations, seeding)
CREATE POLICY "service_role_all_employees"
  ON employees
  TO service_role
  USING (true)
  WITH CHECK (true);
