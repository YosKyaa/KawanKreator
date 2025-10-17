-- =========================================================
-- Kawan Kreator – Full Database Schema (STRICT-COMPAT)
-- Target: PostgreSQL (Supabase compatible)
-- Date: 2025-10-16
-- Highlights:
-- - Extensions: pgcrypto, citext, btree_gist
-- - RLS policies (owner-based, auth.uid())
-- - Indexes, constraints, triggers (WITHOUT "IF NOT EXISTS" on CREATE TRIGGER)
-- - Calendar overlap prevention via slot_period + trigger (no functions in index)
-- - MVP: Quick Rate Card + Planner/AI → Calendar Lite
-- - Billing: plans / entitlements / subscriptions / invoices / usage
-- - Seed data for platforms, rate formula v1, plans, entitlements
-- =========================================================

-----------------------------
-- 0) EXTENSIONS
-----------------------------
CREATE EXTENSION IF NOT EXISTS pgcrypto;        -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS citext;          -- case-insensitive text
CREATE EXTENSION IF NOT EXISTS btree_gist;      -- exclusion constraints

-----------------------------
-- 1) SCHEMA-WIDE HELPERS
-----------------------------
-- updated_at trigger function
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

-- helper: compute calendar end_time & slot_period
CREATE OR REPLACE FUNCTION calendar_slots_set_computed()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.end_time := NEW.start_time + (NEW.duration_min * INTERVAL '1 minute');
  NEW.slot_period := tstzrange(NEW.start_time, NEW.end_time, '[)');
  RETURN NEW;
END;
$$;

-----------------------------
-- 2) CORE / FOUNDATION
-----------------------------
-- Users
CREATE TABLE IF NOT EXISTS users (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email           CITEXT UNIQUE,
  display_name    TEXT,
  avatar_url      TEXT,
  role            TEXT NOT NULL DEFAULT 'user',  -- 'user' | 'admin' (future)
  tz              TEXT NOT NULL DEFAULT 'Asia/Jakarta',
  is_guest        BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at      TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_users_email ON users (email) WHERE deleted_at IS NULL;

-- Auth identities (Google, Magic Link, Password)
CREATE TABLE IF NOT EXISTS auth_identities (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider        TEXT NOT NULL CHECK (provider IN ('google','magic_link','password')),
  provider_uid    TEXT,               -- Google sub, or hashed email, etc.
  email           CITEXT,             -- denormalized for fast lookup
  password_hash   TEXT,               -- only for 'password' provider
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (provider, provider_uid)
);
CREATE INDEX IF NOT EXISTS idx_auth_email ON auth_identities (email);

-- User preferences (setup 60 detik)
CREATE TABLE IF NOT EXISTS user_preferences (
  user_id         UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  niche           TEXT,
  primary_platform TEXT,  -- FK to rate_platforms(code) will be added after rate_platforms exists
  weekly_target   INT CHECK (weekly_target IN (0,1,2,3,4,5,6,7)) DEFAULT 3,
  preferred_times TEXT[] NOT NULL DEFAULT ARRAY['16:00'],
  meta            JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-----------------------------
-- 3) REFERENCE TABLES
-----------------------------
-- Platforms reference
CREATE TABLE IF NOT EXISTS rate_platforms (
  code            TEXT PRIMARY KEY,          -- 'instagram','tiktok','youtube'
  title           TEXT NOT NULL
);

-- After rate_platforms exists, add FK for user_preferences.primary_platform
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_name='user_preferences' AND column_name='primary_platform') THEN
    BEGIN
      ALTER TABLE user_preferences
        ADD CONSTRAINT fk_prefs_platform
        FOREIGN KEY (primary_platform) REFERENCES rate_platforms(code);
    EXCEPTION WHEN duplicate_object THEN NULL; END;
  END IF;
END$$;

-- Rate formula configurations (rule-based baseline)
CREATE TABLE IF NOT EXISTS rate_formula_configs (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  version             INT NOT NULL,
  alpha               NUMERIC(6,4) NOT NULL,     -- followers exponent
  beta                NUMERIC(6,4) NOT NULL,     -- ER coefficient
  base_table          JSONB NOT NULL,            -- {"instagram": 100000, ...}
  scope_multipliers   JSONB NOT NULL,            -- {"reel":1.2,"post":1.0,"story":0.6}
  niche_multipliers   JSONB NOT NULL DEFAULT '{}'::jsonb,
  active              BOOLEAN NOT NULL DEFAULT TRUE,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (version)
);
-- Ensure only one active formula
CREATE UNIQUE INDEX IF NOT EXISTS uq_rate_formula_active_true
ON rate_formula_configs ((active))
WHERE active = TRUE;

-----------------------------
-- 4) QUICK RATE CARD
-----------------------------
-- Estimates (calculated results) incl. optional AI fields
CREATE TABLE IF NOT EXISTS ratecard_estimates (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID REFERENCES users(id) ON DELETE SET NULL, -- NULL if guest
  formula_version     INT NOT NULL,
  platform            TEXT NOT NULL REFERENCES rate_platforms(code),
  followers           BIGINT CHECK (followers >= 0),
  er_pct              NUMERIC(5,2) CHECK (er_pct >= 0 AND er_pct <= 100),
  scope_items         TEXT[] NOT NULL,           -- e.g. ['reel','story']
  niche               TEXT,
  params_extra        JSONB NOT NULL DEFAULT '{}'::jsonb,  -- usage rights, contexts
  result_recommended  BIGINT NOT NULL,
  result_min          BIGINT NOT NULL,
  result_max          BIGINT NOT NULL,
  breakdown           JSONB NOT NULL,           -- transparent components

  -- AI enhancer (optional)
  ai_adjustment_pct   NUMERIC(5,2),
  ai_recommended      BIGINT,
  ai_explanation      TEXT,
  ai_model            TEXT,
  ai_latency_ms       INT,

  -- User's chosen final
  final_recommended   BIGINT,
  source              TEXT NOT NULL DEFAULT 'rule', -- 'rule' | 'ai' | 'mixed'

  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_ratecard_estimates_user ON ratecard_estimates (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ratecard_estimates_platform ON ratecard_estimates (platform, created_at DESC);
DO $$
BEGIN
  BEGIN
    ALTER TABLE ratecard_estimates
      ADD CONSTRAINT chk_rate_bounds
      CHECK (result_min <= result_recommended AND result_recommended <= result_max);
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    ALTER TABLE ratecard_estimates
      ADD CONSTRAINT chk_ai_pair
      CHECK ((ai_adjustment_pct IS NULL AND ai_recommended IS NULL)
          OR (ai_adjustment_pct IS NOT NULL AND ai_recommended IS NOT NULL));
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

-- Templates
CREATE TABLE IF NOT EXISTS ratecard_templates (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name                TEXT NOT NULL,
  payload             JSONB NOT NULL,          -- full template (params + result)
  is_public           BOOLEAN NOT NULL DEFAULT FALSE,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at          TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_ratecard_templates_user ON ratecard_templates (user_id) WHERE deleted_at IS NULL;

-- Exports
CREATE TABLE IF NOT EXISTS exports (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID REFERENCES users(id) ON DELETE SET NULL,
  entity_type         TEXT NOT NULL CHECK (entity_type IN ('ratecard_template')),
  entity_id           UUID NOT NULL,
  format              TEXT NOT NULL CHECK (format IN ('png','pdf')),
  download_url        TEXT NOT NULL,
  meta                JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_exports_user ON exports (user_id, created_at DESC);

-----------------------------
-- 5) PLANNER/AI → IDEAS
-----------------------------
CREATE TABLE IF NOT EXISTS ideas (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES users(id) ON DELETE SET NULL,   -- NULL for guest/local-only
  niche           TEXT,
  platform        TEXT NOT NULL REFERENCES rate_platforms(code),
  title           TEXT NOT NULL,
  hook            TEXT,
  caption         TEXT,
  hashtags        TEXT[],
  source          TEXT NOT NULL DEFAULT 'ai',  -- 'ai' | 'manual' | 'import'
  meta            JSONB NOT NULL DEFAULT '{}'::jsonb,  -- prompt, model, score, etc
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_ideas_user ON ideas (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ideas_platform ON ideas (platform, created_at DESC);
CREATE INDEX IF NOT EXISTS gin_ideas_meta ON ideas USING GIN (meta);

-----------------------------
-- 6) CALENDAR LITE (slot_period + trigger approach)
-----------------------------
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'slot_status') THEN
    CREATE TYPE slot_status AS ENUM ('planned','done','canceled');
  END IF;
END$$;

CREATE TABLE IF NOT EXISTS calendar_slots (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  idea_id         UUID REFERENCES ideas(id) ON DELETE SET NULL,
  platform        TEXT NOT NULL REFERENCES rate_platforms(code),
  start_time      TIMESTAMPTZ NOT NULL,
  duration_min    INT NOT NULL DEFAULT 0,
  title           TEXT NOT NULL,
  notes           TEXT,
  status          slot_status NOT NULL DEFAULT 'planned',
  meta            JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at      TIMESTAMPTZ,
  -- computed by trigger
  end_time        TIMESTAMPTZ,
  slot_period     tstzrange
);

-- Anti-duplicate shortcut (optional exact match)
CREATE UNIQUE INDEX IF NOT EXISTS uq_slot_user_platform_time
ON calendar_slots (user_id, platform, start_time)
WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_slots_user_time ON calendar_slots (user_id, start_time DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_slots_status ON calendar_slots (user_id, status) WHERE deleted_at IS NULL;

-- Trigger (STRICT: no IF NOT EXISTS on CREATE)
DROP TRIGGER IF EXISTS trg_calendar_slots_set_computed ON calendar_slots;
CREATE TRIGGER trg_calendar_slots_set_computed
BEFORE INSERT OR UPDATE OF start_time, duration_min
ON calendar_slots
FOR EACH ROW
EXECUTE FUNCTION calendar_slots_set_computed();

-- Exclusion constraint using slot_period (no functions in index)
ALTER TABLE calendar_slots
  DROP CONSTRAINT IF EXISTS ex_slots_no_overlap;

ALTER TABLE calendar_slots
  ADD CONSTRAINT ex_slots_no_overlap
  EXCLUDE USING gist (
    user_id WITH =,
    platform WITH =,
    slot_period WITH &&
  )
  WHERE (deleted_at IS NULL AND status <> 'canceled');

-----------------------------
-- 7) ANALYTICS & NOTIFICATIONS
-----------------------------
CREATE TABLE IF NOT EXISTS analytics_weekly (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  week_start      DATE NOT NULL,  -- ISO Monday
  posts_planned   INT NOT NULL DEFAULT 0,
  posts_done      INT NOT NULL DEFAULT 0,
  top_content_ref JSONB,
  er_avg          NUMERIC(6,4),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, week_start)
);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notif_type') THEN
    CREATE TYPE notif_type AS ENUM ('calendar_reminder','weekly_digest','feature_update');
  END IF;
END$$;

CREATE TABLE IF NOT EXISTS notifications (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type            notif_type NOT NULL,
  schedule_time   TIMESTAMPTZ NOT NULL,
  payload         JSONB NOT NULL DEFAULT '{}'::jsonb,  -- {slot_id, title, deeplink}
  status          TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled','sent','canceled')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  sent_at         TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_notif_user_time ON notifications (user_id, schedule_time, status);
CREATE INDEX IF NOT EXISTS gin_notif_payload ON notifications USING GIN (payload);

-----------------------------
-- 8) HELP / FEEDBACK
-----------------------------
CREATE TABLE IF NOT EXISTS faqs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug            TEXT UNIQUE NOT NULL,
  title           TEXT NOT NULL,
  body_md         TEXT NOT NULL,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS feedbacks (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES users(id) ON DELETE SET NULL,
  category        TEXT CHECK (category IN ('bug','ux','feature','other')) DEFAULT 'other',
  description     TEXT NOT NULL,
  attachments     JSONB NOT NULL DEFAULT '[]'::jsonb,
  app_context     JSONB NOT NULL DEFAULT '{}'::jsonb,  -- screen, version, device
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_feedback_user ON feedbacks (user_id, created_at DESC);

-----------------------------
-- 9) TELEMETRY (optional but handy)
-----------------------------
CREATE TABLE IF NOT EXISTS events (
  id              BIGSERIAL PRIMARY KEY,
  user_id         UUID REFERENCES users(id) ON DELETE SET NULL,
  name            TEXT NOT NULL,
  params          JSONB NOT NULL DEFAULT '{}'::jsonb,
  occurred_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_events_user_time ON events (user_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_events_name_time ON events (name, occurred_at DESC);

-----------------------------
-- 10) BILLING: PLANS / ENTITLEMENTS / SUBSCRIPTIONS / INVOICES / USAGE
-----------------------------
CREATE TABLE IF NOT EXISTS plans (
  id              TEXT PRIMARY KEY,              -- 'free','pro_month','pro_year'
  title           TEXT NOT NULL,
  price_cents     INT NOT NULL DEFAULT 0,
  currency        TEXT NOT NULL DEFAULT 'IDR',
  interval        TEXT NOT NULL DEFAULT 'none',  -- 'none'|'month'|'year'
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  metadata        JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS plan_entitlements (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id         TEXT NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
  feature_key     TEXT NOT NULL,              -- 'ratecard.calculate_per_day', etc.
  limit_value     INT,                        -- NULL => unlimited
  is_enabled      BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE (plan_id, feature_key)
);

CREATE TABLE IF NOT EXISTS user_subscriptions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan_id         TEXT NOT NULL REFERENCES plans(id),
  status          TEXT NOT NULL CHECK (status IN ('active','past_due','canceled','expired','trial')),
  start_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  current_period_end TIMESTAMPTZ,
  cancel_at       TIMESTAMPTZ,
  provider        TEXT,                       -- 'xendit'|'midtrans'|'stripe'
  provider_ref    TEXT,
  metadata        JSONB NOT NULL DEFAULT '{}'::jsonb
);
CREATE INDEX IF NOT EXISTS idx_user_sub_active ON user_subscriptions (user_id, status);

CREATE TABLE IF NOT EXISTS invoices (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan_id         TEXT NOT NULL REFERENCES plans(id),
  amount_cents    INT NOT NULL,
  currency        TEXT NOT NULL DEFAULT 'IDR',
  status          TEXT NOT NULL CHECK (status IN ('pending','paid','failed','refunded')),
  provider        TEXT,
  provider_ref    TEXT,
  issued_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  paid_at         TIMESTAMPTZ,
  metadata        JSONB NOT NULL DEFAULT '{}'::jsonb
);
CREATE INDEX IF NOT EXISTS idx_invoices_user ON invoices (user_id, issued_at DESC);

CREATE TABLE IF NOT EXISTS usage_counters (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  feature_key     TEXT NOT NULL,
  period_date     DATE NOT NULL,              -- daily window
  used            INT NOT NULL DEFAULT 0,
  UNIQUE (user_id, feature_key, period_date)
);

-- (Optional) coupons
CREATE TABLE IF NOT EXISTS coupons (
  code            TEXT PRIMARY KEY,
  discount_pct    INT CHECK (discount_pct BETWEEN 0 AND 100),
  valid_from      TIMESTAMPTZ,
  valid_until     TIMESTAMPTZ,
  max_redemption  INT,
  redeemed        INT NOT NULL DEFAULT 0,
  metadata        JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS user_coupon_redemptions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  coupon_code     TEXT NOT NULL REFERENCES coupons(code),
  redeemed_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, coupon_code)
);

-----------------------------
-- 11) RLS ENABLE + POLICIES (OWNER-BASED)
-----------------------------
-- Enable RLS
ALTER TABLE IF EXISTS users                ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_preferences     ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS ideas                ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS calendar_slots       ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS ratecard_estimates   ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS ratecard_templates   ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS analytics_weekly     ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS notifications        ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS exports              ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS feedbacks            ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS events               ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_subscriptions   ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS invoices             ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS usage_counters       ENABLE ROW LEVEL SECURITY;

-- Users: owner can select/update self
DO $$
BEGIN
  BEGIN
    CREATE POLICY p_users_select_self ON users
      FOR SELECT USING (auth.uid() = id);
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY p_users_update_self ON users
      FOR UPDATE USING (auth.uid() = id);
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

-- Preferences (owner only)
DO $$
BEGIN
  BEGIN
    CREATE POLICY p_prefs_owner_all ON user_preferences
      FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

-- Ideas (guest rows may be NULL owner)
DO $$
BEGIN
  BEGIN
    CREATE POLICY p_ideas_owner_all ON ideas
      FOR ALL USING (user_id IS NULL OR user_id = auth.uid())
      WITH CHECK (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

-- Calendar slots
DO $$
BEGIN
  BEGIN
    CREATE POLICY p_slots_owner_all ON calendar_slots
      FOR ALL USING (user_id = auth.uid())
      WITH CHECK (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

-- Ratecard estimates
DO $$
BEGIN
  BEGIN
    CREATE POLICY p_estimates_owner_all ON ratecard_estimates
      FOR ALL USING (user_id IS NULL OR user_id = auth.uid())
      WITH CHECK (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

-- Templates
DO $$
BEGIN
  BEGIN
    CREATE POLICY p_templates_owner_all ON ratecard_templates
      FOR ALL USING (user_id = auth.uid())
      WITH CHECK (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

-- Analytics weekly
DO $$
BEGIN
  BEGIN
    CREATE POLICY p_analytics_owner ON analytics_weekly
      FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

-- Notifications
DO $$
BEGIN
  BEGIN
    CREATE POLICY p_notifications_owner ON notifications
      FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

-- Exports
DO $$
BEGIN
  BEGIN
    CREATE POLICY p_exports_owner ON exports
      FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

-- Feedbacks
DO $$
BEGIN
  BEGIN
    CREATE POLICY p_feedbacks_owner ON feedbacks
      FOR ALL USING (user_id IS NULL OR user_id = auth.uid())
      WITH CHECK (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

-- Events
DO $$
BEGIN
  BEGIN
    CREATE POLICY p_events_owner ON events
      FOR ALL USING (user_id IS NULL OR user_id = auth.uid())
      WITH CHECK (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

-- Subscriptions
DO $$
BEGIN
  BEGIN
    CREATE POLICY p_subs_owner ON user_subscriptions
      FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

-- Invoices
DO $$
BEGIN
  BEGIN
    CREATE POLICY p_invoices_owner ON invoices
      FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

-- Usage counters
DO $$
BEGIN
  BEGIN
    CREATE POLICY p_usage_owner ON usage_counters
      FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

-----------------------------
-- 12) TRIGGERS (DROP+CREATE, no IF NOT EXISTS)
-----------------------------
-- users
DROP TRIGGER IF EXISTS trg_users_updated ON users;
CREATE TRIGGER trg_users_updated
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- user_preferences
DROP TRIGGER IF EXISTS trg_prefs_updated ON user_preferences;
CREATE TRIGGER trg_prefs_updated
BEFORE UPDATE ON user_preferences
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ideas
DROP TRIGGER IF EXISTS trg_ideas_updated ON ideas;
CREATE TRIGGER trg_ideas_updated
BEFORE UPDATE ON ideas
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- calendar_slots
DROP TRIGGER IF EXISTS trg_slots_updated ON calendar_slots;
CREATE TRIGGER trg_slots_updated
BEFORE UPDATE ON calendar_slots
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ratecard_estimates
DROP TRIGGER IF EXISTS trg_rate_estimates_updated ON ratecard_estimates;
CREATE TRIGGER trg_rate_estimates_updated
BEFORE UPDATE ON ratecard_estimates
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ratecard_templates
DROP TRIGGER IF EXISTS trg_templates_updated ON ratecard_templates;
CREATE TRIGGER trg_templates_updated
BEFORE UPDATE ON ratecard_templates
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- notifications
DROP TRIGGER IF EXISTS trg_notifications_updated ON notifications;
CREATE TRIGGER trg_notifications_updated
BEFORE UPDATE ON notifications
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- faqs
DROP TRIGGER IF EXISTS trg_faqs_updated ON faqs;
CREATE TRIGGER trg_faqs_updated
BEFORE UPDATE ON faqs
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-----------------------------
-- 13) SEED DATA (minimal)
-----------------------------
-- Platforms
INSERT INTO rate_platforms (code, title) VALUES
  ('instagram','Instagram'),
  ('tiktok','TikTok'),
  ('youtube','YouTube')
ON CONFLICT (code) DO NOTHING;

-- Rate formula v1 (example)
INSERT INTO rate_formula_configs (version, alpha, beta, base_table, scope_multipliers, niche_multipliers, active)
VALUES (
  1,
  0.85,
  0.10,
  '{"instagram": 100000, "tiktok": 90000, "youtube": 120000}',
  '{"reel": 1.2, "post": 1.0, "story": 0.6, "short": 1.15}',
  '{}',
  TRUE
)
ON CONFLICT (version) DO NOTHING;

-- Plans
INSERT INTO plans (id, title, price_cents, currency, interval, is_active) VALUES
 ('free','Free',0,'IDR','none',TRUE),
 ('pro_month','Pro Monthly',4900000,'IDR','month',TRUE),
 ('pro_year','Pro Yearly',49000000,'IDR','year',TRUE)
ON CONFLICT (id) DO NOTHING;

-- Entitlements
INSERT INTO plan_entitlements (plan_id, feature_key, limit_value, is_enabled) VALUES
 ('free','ratecard.calculate_per_day', 3, TRUE),
 ('free','ratecard.templates_saved',   2, TRUE),
 ('free','export.pdf_enabled',         0, TRUE),
 ('free','export.watermark_enabled',   1, TRUE),
 ('free','ideas.generate_per_day',    10, TRUE),
 ('free','calendar.active_slots_per_week', 10, TRUE),

 ('pro_month','ratecard.calculate_per_day', NULL, TRUE),
 ('pro_month','ratecard.templates_saved',   NULL, TRUE),
 ('pro_month','export.pdf_enabled',         1, TRUE),
 ('pro_month','export.watermark_enabled',   0, TRUE),
 ('pro_month','ideas.generate_per_day',     100, TRUE),
 ('pro_month','calendar.active_slots_per_week', NULL, TRUE),

 ('pro_year','ratecard.calculate_per_day', NULL, TRUE),
 ('pro_year','ratecard.templates_saved',   NULL, TRUE),
 ('pro_year','export.pdf_enabled',         1, TRUE),
 ('pro_year','export.watermark_enabled',   0, TRUE),
 ('pro_year','ideas.generate_per_day',     100, TRUE),
 ('pro_year','calendar.active_slots_per_week', NULL, TRUE)
ON CONFLICT DO NOTHING;

-- Backfill computed columns for existing calendar rows (if any)
UPDATE calendar_slots
SET duration_min = duration_min
WHERE end_time IS NULL OR slot_period IS NULL;

-- =========================================================
-- END OF SCHEMA
-- =========================================================
