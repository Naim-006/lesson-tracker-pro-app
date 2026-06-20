-- =============================================================
-- FIX: RLS recursion (42P17) + permission denied (42501)
-- Run this entire file in Supabase SQL Editor
-- =============================================================

-- 1. Drop old function if it exists, then recreate with proper grants
DROP FUNCTION IF EXISTS public.is_admin();

CREATE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
$$;

-- Grant execute to both anon and authenticated roles
GRANT EXECUTE ON FUNCTION public.is_admin() TO anon, authenticated;

-- 2. Fix the profiles policy (root cause of infinite recursion)
DROP POLICY IF EXISTS "admins_read_all_profiles" ON profiles;
CREATE POLICY "admins_read_all_profiles" ON profiles
  FOR SELECT USING (public.is_admin());

-- 3. Fix all other admin policies
DROP POLICY IF EXISTS "admins_read_all_pupils" ON pupils;
CREATE POLICY "admins_read_all_pupils" ON pupils
  FOR SELECT USING (public.is_admin());

DROP POLICY IF EXISTS "admins_manage_subscriptions" ON instructor_subscriptions;
CREATE POLICY "admins_manage_subscriptions" ON instructor_subscriptions
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "admins_manage_plans" ON subscription_plans;
CREATE POLICY "admins_manage_plans" ON subscription_plans
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "admins_manage_promo_codes" ON promo_codes;
CREATE POLICY "admins_manage_promo_codes" ON promo_codes
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "admins_manage_banners" ON banners;
CREATE POLICY "admins_manage_banners" ON banners
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "admins_manage_app_settings" ON app_settings;
CREATE POLICY "admins_manage_app_settings" ON app_settings
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "admins_read_locations" ON instructor_locations;
CREATE POLICY "admins_read_locations" ON instructor_locations
  FOR SELECT USING (public.is_admin());

DROP POLICY IF EXISTS "admins_manage_payment_requests" ON instructor_payment_requests;
CREATE POLICY "admins_manage_payment_requests" ON instructor_payment_requests
  FOR ALL USING (public.is_admin());

-- 4. Auth trigger (auto-create profile on signup)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, phone, role, email_verified)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.email, ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    COALESCE(NEW.raw_user_meta_data->>'role', 'instructor'),
    FALSE
  );
  RETURN NEW;
END;
$$;

GRANT EXECUTE ON FUNCTION public.handle_new_user() TO anon, authenticated;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================================
-- FIX COMPLETE
-- =============================================================
