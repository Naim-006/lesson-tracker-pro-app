-- Fix 1: Allow profile inserts (fixes "violates row-level security")
DROP POLICY IF EXISTS "insert_own_profile" ON profiles;
DROP POLICY IF EXISTS "insert_profile" ON profiles;
DROP POLICY IF EXISTS "allow_insert" ON profiles;
CREATE POLICY "insert_profile" ON profiles FOR INSERT WITH CHECK (true);

-- Fix 2: Grant permissions on profiles
GRANT ALL ON profiles TO anon, authenticated;

-- Fix 3: Recreate is_admin() and fix admin read policy
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql SECURITY DEFINER SET search_path = public STABLE
AS $$ SELECT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') $$;

DROP POLICY IF EXISTS "admins_read_all_profiles" ON profiles;
DROP POLICY IF EXISTS "allow_admin_read" ON profiles;
DROP POLICY IF EXISTS "admin_read_profiles" ON profiles;
CREATE POLICY "admin_read_profiles" ON profiles FOR SELECT USING (public.is_admin());

-- Fix 4: Grant on instructor_subscriptions (fixes admin dashboard)
GRANT ALL ON instructor_subscriptions TO anon, authenticated;
