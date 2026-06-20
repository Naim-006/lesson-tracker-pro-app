-- =============================================================
-- CLEAN RESET: Run ONCE, fixes everything
-- =============================================================

-- Drop all policies on profiles (every possible name)
DROP POLICY IF EXISTS "insert_own_profile" ON profiles;
DROP POLICY IF EXISTS "insert_profile" ON profiles;
DROP POLICY IF EXISTS "allow_insert" ON profiles;
DROP POLICY IF EXISTS "users_read_own_profile" ON profiles;
DROP POLICY IF EXISTS "allow_read_own" ON profiles;
DROP POLICY IF EXISTS "users_update_own_profile" ON profiles;
DROP POLICY IF EXISTS "allow_update_own" ON profiles;
DROP POLICY IF EXISTS "admins_read_all_profiles" ON profiles;
DROP POLICY IF EXISTS "allow_admin_read" ON profiles;

-- Recreate is_admin() function
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql SECURITY DEFINER SET search_path = public STABLE
AS $$ SELECT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') $$;

-- Fresh policies
CREATE POLICY "insert_profile" ON profiles FOR INSERT WITH CHECK (true);
CREATE POLICY "read_own_profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "update_own_profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "admin_read_profiles" ON profiles FOR SELECT USING (public.is_admin());

-- Grants - each wrapped to skip missing tables
DO $$ BEGIN EXECUTE 'GRANT ALL ON profiles TO anon, authenticated'; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN EXECUTE 'GRANT ALL ON instructor_subscriptions TO anon, authenticated'; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN EXECUTE 'GRANT ALL ON subscription_plans TO anon, authenticated'; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN EXECUTE 'GRANT ALL ON pupils TO anon, authenticated'; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN EXECUTE 'GRANT ALL ON instructor_pupil_links TO anon, authenticated'; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN EXECUTE 'GRANT ALL ON lessons TO anon, authenticated'; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN EXECUTE 'GRANT ALL ON open_slots TO anon, authenticated'; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN EXECUTE 'GRANT ALL ON transactions TO anon, authenticated'; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN EXECUTE 'GRANT ALL ON invoices TO anon, authenticated'; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN EXECUTE 'GRANT ALL ON messages TO anon, authenticated'; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN EXECUTE 'GRANT ALL ON notifications TO anon, authenticated'; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN EXECUTE 'GRANT ALL ON enquiries TO anon, authenticated'; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN EXECUTE 'GRANT ALL ON test_reports TO anon, authenticated'; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN EXECUTE 'GRANT ALL ON mileage_entries TO anon, authenticated'; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN EXECUTE 'GRANT ALL ON vehicles TO anon, authenticated'; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN EXECUTE 'GRANT ALL ON progress_categories TO anon, authenticated'; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN EXECUTE 'GRANT ALL ON progress_skills TO anon, authenticated'; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN EXECUTE 'GRANT ALL ON teaching_resources TO anon, authenticated'; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN EXECUTE 'GRANT ALL ON instructor_activity_logs TO anon, authenticated'; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN EXECUTE 'GRANT ALL ON promo_codes TO anon, authenticated'; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN EXECUTE 'GRANT ALL ON banners TO anon, authenticated'; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN EXECUTE 'GRANT ALL ON app_settings TO anon, authenticated'; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN EXECUTE 'GRANT ALL ON instructor_locations TO anon, authenticated'; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN EXECUTE 'GRANT ALL ON instructor_payment_requests TO anon, authenticated'; EXCEPTION WHEN OTHERS THEN NULL; END $$;
DO $$ BEGIN EXECUTE 'GRANT ALL ON pupil_invitations TO anon, authenticated'; EXCEPTION WHEN OTHERS THEN NULL; END $$;

-- =============================================================
-- DONE
-- =============================================================
