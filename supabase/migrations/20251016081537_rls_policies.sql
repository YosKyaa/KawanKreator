-- =========================================================
-- Kawan Kreator – RLS Policy Pack (owner-based + public refs)
-- Date: 2025-10-16
-- Notes:
-- - Enable RLS where needed (idempotent).
-- - Policies created inside DO blocks (ignore duplicate_object).
-- - Uses Supabase helpers: auth.uid(), auth.role().
-- - Reference tables are readable by everyone (SELECT).
-- - Writes on sensitive tables restricted to owner or service_role.
-- =========================================================

------------------------------------------------------------
-- 0) ENABLE RLS (if not already)
------------------------------------------------------------
-- Core
ALTER TABLE IF EXISTS users                ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS auth_identities      ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_preferences     ENABLE ROW LEVEL SECURITY;

-- Features
ALTER TABLE IF EXISTS rate_platforms       ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS rate_formula_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS ideas                ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS calendar_slots       ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS ratecard_estimates   ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS ratecard_templates   ENABLE ROW LEVEL SECURITY;

-- Analytics / Notifications / Exports / Help / Telemetry
ALTER TABLE IF EXISTS analytics_weekly     ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS notifications        ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS exports              ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS faqs                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS feedbacks            ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS events               ENABLE ROW LEVEL SECURITY;

-- Billing
ALTER TABLE IF EXISTS plans                ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS plan_entitlements    ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_subscriptions   ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS invoices             ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS usage_counters       ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS coupons              ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_coupon_redemptions ENABLE ROW LEVEL SECURITY;

------------------------------------------------------------
-- 1) REFERENCE TABLES (public read, admin/service write)
------------------------------------------------------------
DO $$
BEGIN
  -- rate_platforms
  BEGIN
    CREATE POLICY r_rate_platforms_public ON rate_platforms
      FOR SELECT USING (true);
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY w_rate_platforms_admin ON rate_platforms
      FOR ALL USING (auth.role() = 'service_role' OR EXISTS (
        SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'
      ))
      WITH CHECK (auth.role() = 'service_role' OR EXISTS (
        SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'
      ));
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  -- rate_formula_configs
  BEGIN
    CREATE POLICY r_rate_formula_public ON rate_formula_configs
      FOR SELECT USING (true);
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY w_rate_formula_admin ON rate_formula_configs
      FOR ALL USING (auth.role() = 'service_role' OR EXISTS (
        SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'
      ))
      WITH CHECK (auth.role() = 'service_role' OR EXISTS (
        SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'
      ));
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  -- faqs (public read; admin/service write)
  BEGIN
    CREATE POLICY r_faqs_public ON faqs
      FOR SELECT USING (true);
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY w_faqs_admin ON faqs
      FOR ALL USING (auth.role() = 'service_role' OR EXISTS (
        SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'
      ))
      WITH CHECK (auth.role() = 'service_role' OR EXISTS (
        SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'
      ));
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  -- plans (public read; admin/service write)
  BEGIN
    CREATE POLICY r_plans_public ON plans
      FOR SELECT USING (true);
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY w_plans_admin ON plans
      FOR ALL USING (auth.role() = 'service_role' OR EXISTS (
        SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'
      ))
      WITH CHECK (auth.role() = 'service_role' OR EXISTS (
        SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'
      ));
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  -- plan_entitlements (public read; admin/service write)
  BEGIN
    CREATE POLICY r_plan_entitlements_public ON plan_entitlements
      FOR SELECT USING (true);
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY w_plan_entitlements_admin ON plan_entitlements
      FOR ALL USING (auth.role() = 'service_role' OR EXISTS (
        SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'
      ))
      WITH CHECK (auth.role() = 'service_role' OR EXISTS (
        SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'
      ));
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  -- coupons (public read; admin/service write)
  BEGIN
    CREATE POLICY r_coupons_public ON coupons
      FOR SELECT USING (true);
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY w_coupons_admin ON coupons
      FOR ALL USING (auth.role() = 'service_role' OR EXISTS (
        SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'
      ))
      WITH CHECK (auth.role() = 'service_role' OR EXISTS (
        SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'
      ));
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

------------------------------------------------------------
-- 2) USERS & AUTH IDENTITIES
------------------------------------------------------------
DO $$
BEGIN
  -- users: self read & update; insert via service_role or matching uid
  BEGIN
    CREATE POLICY r_users_self ON users
      FOR SELECT USING (auth.uid() = id);
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY u_users_self ON users
      FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY i_users_signup ON users
      FOR INSERT WITH CHECK (
        auth.role() = 'service_role' OR auth.uid() = id
      );
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  -- auth_identities: restrict to service_role only
  BEGIN
    CREATE POLICY r_auth_ids_service ON auth_identities
      FOR SELECT USING (auth.role() = 'service_role');
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY w_auth_ids_service ON auth_identities
      FOR ALL USING (auth.role() = 'service_role')
      WITH CHECK (auth.role() = 'service_role');
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

------------------------------------------------------------
-- 3) USER PREFERENCES (owner only)
------------------------------------------------------------
DO $$
BEGIN
  BEGIN
    CREATE POLICY all_prefs_owner ON user_preferences
      FOR ALL USING (user_id = auth.uid())
      WITH CHECK (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

------------------------------------------------------------
-- 4) IDEAS (owner only)
------------------------------------------------------------
DO $$
BEGIN
  BEGIN
    CREATE POLICY r_ideas_owner ON ideas
      FOR SELECT USING (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY i_ideas_owner ON ideas
      FOR INSERT WITH CHECK (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY w_ideas_owner ON ideas
      FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY d_ideas_owner ON ideas
      FOR DELETE USING (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

------------------------------------------------------------
-- 5) CALENDAR SLOTS (owner only)
------------------------------------------------------------
DO $$
BEGIN
  BEGIN
    CREATE POLICY r_slots_owner ON calendar_slots
      FOR SELECT USING (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY i_slots_owner ON calendar_slots
      FOR INSERT WITH CHECK (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY w_slots_owner ON calendar_slots
      FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY d_slots_owner ON calendar_slots
      FOR DELETE USING (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

------------------------------------------------------------
-- 6) RATECARD ESTIMATES (owner only)
--    Catatan: Untuk "guest mode", JANGAN simpan ke DB.
------------------------------------------------------------
DO $$
BEGIN
  BEGIN
    CREATE POLICY r_estimates_owner ON ratecard_estimates
      FOR SELECT USING (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY i_estimates_owner ON ratecard_estimates
      FOR INSERT WITH CHECK (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY w_estimates_owner ON ratecard_estimates
      FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY d_estimates_owner ON ratecard_estimates
      FOR DELETE USING (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

------------------------------------------------------------
-- 7) RATECARD TEMPLATES (owner; public view if is_public=TRUE)
------------------------------------------------------------
DO $$
BEGIN
  BEGIN
    CREATE POLICY r_templates_owner_or_public ON ratecard_templates
      FOR SELECT USING (user_id = auth.uid() OR is_public = TRUE);
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY i_templates_owner ON ratecard_templates
      FOR INSERT WITH CHECK (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY w_templates_owner ON ratecard_templates
      FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY d_templates_owner ON ratecard_templates
      FOR DELETE USING (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

------------------------------------------------------------
-- 8) ANALYTICS WEEKLY (owner)
------------------------------------------------------------
DO $$
BEGIN
  BEGIN
    CREATE POLICY r_analytics_owner ON analytics_weekly
      FOR SELECT USING (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY w_analytics_owner ON analytics_weekly
      FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

------------------------------------------------------------
-- 9) NOTIFICATIONS (owner)
------------------------------------------------------------
DO $$
BEGIN
  BEGIN
    CREATE POLICY r_notifications_owner ON notifications
      FOR SELECT USING (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY w_notifications_owner ON notifications
      FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

------------------------------------------------------------
-- 10) EXPORTS (owner read; insert by owner/service)
------------------------------------------------------------
DO $$
BEGIN
  BEGIN
    CREATE POLICY r_exports_owner ON exports
      FOR SELECT USING (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY i_exports_owner_or_service ON exports
      FOR INSERT WITH CHECK (user_id = auth.uid() OR auth.role() = 'service_role');
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

------------------------------------------------------------
-- 11) FEEDBACKS (owner; allow anonymous insert with NULL user_id)
------------------------------------------------------------
DO $$
BEGIN
  BEGIN
    CREATE POLICY r_feedbacks_owner ON feedbacks
      FOR SELECT USING (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY i_feedbacks_owner_or_anon ON feedbacks
      FOR INSERT WITH CHECK (user_id = auth.uid() OR user_id IS NULL);
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

------------------------------------------------------------
-- 12) EVENTS (write-only; optional read for owner)
------------------------------------------------------------
DO $$
BEGIN
  -- insert by owner or service (e.g., server logs)
  BEGIN
    CREATE POLICY i_events_owner_or_service ON events
      FOR INSERT WITH CHECK (user_id = auth.uid() OR auth.role() = 'service_role');
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  -- (optional) owner can read their own events
  BEGIN
    CREATE POLICY r_events_owner ON events
      FOR SELECT USING (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

------------------------------------------------------------
-- 13) BILLING TABLES
------------------------------------------------------------
DO $$
BEGIN
  -- user_subscriptions
  BEGIN
    CREATE POLICY r_subs_owner ON user_subscriptions
      FOR SELECT USING (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY w_subs_service ON user_subscriptions
      FOR ALL USING (auth.role() = 'service_role')
      WITH CHECK (auth.role() = 'service_role');
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  -- invoices
  BEGIN
    CREATE POLICY r_invoices_owner ON invoices
      FOR SELECT USING (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY w_invoices_service ON invoices
      FOR ALL USING (auth.role() = 'service_role')
      WITH CHECK (auth.role() = 'service_role');
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  -- usage_counters: owners can read; writes by service only
  BEGIN
    CREATE POLICY r_usage_owner ON usage_counters
      FOR SELECT USING (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY w_usage_service ON usage_counters
      FOR ALL USING (auth.role() = 'service_role')
      WITH CHECK (auth.role() = 'service_role');
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  -- user_coupon_redemptions
  BEGIN
    CREATE POLICY r_coupon_redemptions_owner ON user_coupon_redemptions
      FOR SELECT USING (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  BEGIN
    CREATE POLICY i_coupon_redemptions_owner ON user_coupon_redemptions
      FOR INSERT WITH CHECK (user_id = auth.uid());
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

-- =========================================================
-- END OF RLS POLICY PACK
-- =========================================================
