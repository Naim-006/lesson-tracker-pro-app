-- =============================================================
-- FIX ALL: Run ONCE in Supabase SQL Editor
-- =============================================================

-- 1. Function to bypass RLS recursion
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql SECURITY DEFINER SET search_path = public STABLE
AS $$ SELECT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') $$;

-- 2. Grant on all existing tables (safe, no error if table missing)
DO $$ BEGIN
  GRANT ALL ON profiles TO anon, authenticated;
EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN GRANT ALL ON pupils TO anon, authenticated; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN GRANT ALL ON instructor_pupil_links TO anon, authenticated; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN GRANT ALL ON pupil_invitations TO anon, authenticated; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN GRANT ALL ON lessons TO anon, authenticated; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN GRANT ALL ON open_slots TO anon, authenticated; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN GRANT ALL ON events TO anon, authenticated; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN GRANT ALL ON transactions TO anon, authenticated; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN GRANT ALL ON invoices TO anon, authenticated; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN GRANT ALL ON messages TO anon, authenticated; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN GRANT ALL ON notifications TO anon, authenticated; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN GRANT ALL ON enquiries TO anon, authenticated; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN GRANT ALL ON test_reports TO anon, authenticated; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN GRANT ALL ON mileage_entries TO anon, authenticated; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN GRANT ALL ON vehicles TO anon, authenticated; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN GRANT ALL ON progress_categories TO anon, authenticated; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN GRANT ALL ON progress_skills TO anon, authenticated; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN GRANT ALL ON teaching_resources TO anon, authenticated; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN GRANT ALL ON instructor_activity_logs TO anon, authenticated; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN GRANT ALL ON instructor_subscriptions TO anon, authenticated; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN GRANT ALL ON subscription_plans TO anon, authenticated; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN GRANT ALL ON promo_codes TO anon, authenticated; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN GRANT ALL ON banners TO anon, authenticated; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN GRANT ALL ON app_settings TO anon, authenticated; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN GRANT ALL ON instructor_locations TO anon, authenticated; EXCEPTION WHEN undefined_table THEN NULL; END $$;
DO $$ BEGIN GRANT ALL ON instructor_payment_requests TO anon, authenticated; EXCEPTION WHEN undefined_table THEN NULL; END $$;

-- 3. Drop FK and add default UUID for profiles
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;
ALTER TABLE profiles ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- 4. Allow any authenticated user to insert profiles
DROP POLICY IF EXISTS "insert_own_profile" ON profiles;
DROP POLICY IF EXISTS "insert_profile" ON profiles;
CREATE POLICY "insert_profile" ON profiles
  FOR INSERT WITH CHECK (true);

-- 5. Fix admin policies (is_admin() avoids recursion)
DROP POLICY IF EXISTS "admins_read_all_profiles" ON profiles;
CREATE POLICY "admins_read_all_profiles" ON profiles
  FOR SELECT USING (public.is_admin());

DROP POLICY IF EXISTS "admins_read_all_pupils" ON pupils;
CREATE POLICY "admins_read_all_pupils" ON pupils FOR SELECT USING (public.is_admin());

DROP POLICY IF EXISTS "admins_manage_subscriptions" ON instructor_subscriptions;
CREATE POLICY "admins_manage_subscriptions" ON instructor_subscriptions FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "admins_manage_plans" ON subscription_plans;
CREATE POLICY "admins_manage_plans" ON subscription_plans FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "admins_manage_promo_codes" ON promo_codes;
CREATE POLICY "admins_manage_promo_codes" ON promo_codes FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "admins_manage_banners" ON banners;
CREATE POLICY "admins_manage_banners" ON banners FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "admins_manage_app_settings" ON app_settings;
CREATE POLICY "admins_manage_app_settings" ON app_settings FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "admins_read_locations" ON instructor_locations;
CREATE POLICY "admins_read_locations" ON instructor_locations FOR SELECT USING (public.is_admin());

DROP POLICY IF EXISTS "admins_manage_payment_requests" ON instructor_payment_requests;
CREATE POLICY "admins_manage_payment_requests" ON instructor_payment_requests FOR ALL USING (public.is_admin());

-- =============================================================
-- FIX COMPLETE
-- =============================================================
