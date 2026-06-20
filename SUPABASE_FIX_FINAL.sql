-- =============================================================
-- FINAL FIX: Run ONCE in Supabase SQL Editor
-- =============================================================

-- 1. Grant table & function permissions to anon/authenticated roles
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

-- 2. Create is_admin() with SECURITY DEFINER (bypasses RLS recursion)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql SECURITY DEFINER SET search_path = public STABLE
AS $$ SELECT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') $$;

-- 3. Drop FK constraint (instructor adds pupil before auth user exists)
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;
ALTER TABLE profiles ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- 4. Fix profile insert policy (allow instructors to create pupil profiles)
DROP POLICY IF EXISTS "insert_own_profile" ON profiles;
CREATE POLICY "insert_profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id OR role = 'pupil');

-- 4. Fix profile select policy (use is_admin() to avoid recursion)
DROP POLICY IF EXISTS "admins_read_all_profiles" ON profiles;
CREATE POLICY "admins_read_all_profiles" ON profiles
  FOR SELECT USING (public.is_admin());

-- 5. Fix all other admin policies
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
