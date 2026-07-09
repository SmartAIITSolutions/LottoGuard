-- ============================================================
-- Migration 001 — organizations, owners, stores
-- LottoGuard multi-tenant foundation (Decision 32)
-- Hierarchy: organizations (agencies) → owners → stores
-- ============================================================

-- ============================================================
-- TABLE: organizations
-- Agencies — SmartAI IT Solutions + future white-label resellers
-- ============================================================
CREATE TABLE organizations (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                TEXT NOT NULL,
  white_label_name    TEXT,
  white_label_domain  TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS: enabled — full user policies added Day 5 once auth system exists
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- Service role has full access (used by Edge Functions and migrations only)
CREATE POLICY "service_role_all_organizations"
  ON organizations
  TO service_role
  USING (true)
  WITH CHECK (true);

-- ============================================================
-- TABLE: owners
-- Store owners — the paying customers
-- One owner belongs to one organization (agency)
-- One owner can have many stores
-- ============================================================
CREATE TABLE owners (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id                UUID NOT NULL REFERENCES organizations (id) ON DELETE RESTRICT,
  name                  TEXT NOT NULL,
  email                 TEXT NOT NULL UNIQUE,
  phone                 TEXT,
  -- Decision 37: owner must accept ToS disclosing employee monitoring
  -- before onboarding wizard can be completed. Null = not yet accepted.
  consent_accepted_at   TIMESTAMPTZ,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index: agency queries filtering by org_id
CREATE INDEX idx_owners_org_id ON owners (org_id);

-- RLS: enabled — full user policies added Day 5 once auth system exists
ALTER TABLE owners ENABLE ROW LEVEL SECURITY;

-- Service role has full access
CREATE POLICY "service_role_all_owners"
  ON owners
  TO service_role
  USING (true)
  WITH CHECK (true);

-- ============================================================
-- TABLE: stores
-- Individual store locations — belong to an owner
-- One owner → many stores (Decision 32 structural requirement)
-- ============================================================
CREATE TABLE stores (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id                  UUID NOT NULL REFERENCES owners (id) ON DELETE RESTRICT,
  name                      TEXT NOT NULL,
  address                   TEXT NOT NULL,
  city                      TEXT NOT NULL,
  state                     TEXT NOT NULL,
  timezone                  TEXT NOT NULL DEFAULT 'America/Chicago',
  -- POS configuration profile (Appendix A, Section A.7, Layer 1)
  pos_brand                 TEXT,
  pos_version               TEXT,
  -- Decision 24: integration path enum
  integration_path          TEXT CHECK (
                              integration_path IN ('pjr', 'csv', 'email', 'zapier', 'lsp', 'manual')
                            ),
  -- Decision 31: confidence tier is ALWAYS auto-detected — never manually set via UI
  -- Values: very_high / high / medium / low
  -- Updated automatically by Edge Function as data sources come online
  confidence_tier           TEXT NOT NULL DEFAULT 'low' CHECK (
                              confidence_tier IN ('very_high', 'high', 'medium', 'low')
                            ),
  -- Decision 26: blocked until real value confirmed on store visit (Appendix A, Section A.9)
  lottery_merchandise_code  TEXT,
  active                    BOOLEAN NOT NULL DEFAULT TRUE,
  created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index: owner queries filtering by owner_id (most common query pattern)
CREATE INDEX idx_stores_owner_id ON stores (owner_id);

-- RLS: enabled — full user policies added Day 5 once auth system exists
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;

-- Service role has full access
CREATE POLICY "service_role_all_stores"
  ON stores
  TO service_role
  USING (true)
  WITH CHECK (true);
