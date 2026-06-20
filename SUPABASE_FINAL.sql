-- =============================================================
-- LESSON TRACKER PRO - FINAL WORKING SCHEMA
-- Matches app code EXACTLY. Run ONCE in Supabase SQL Editor.
-- =============================================================

-- PART 1: ENUMS
CREATE TYPE pupil_status AS ENUM ('current', 'waiting', 'passed', 'archived', 'cancelled');
CREATE TYPE gearbox_type AS ENUM ('any', 'manual', 'automatic');
CREATE TYPE lesson_status AS ENUM ('scheduled', 'completed', 'cancelled', 'no_show');
CREATE TYPE lesson_type AS ENUM ('driving_lesson', 'mock_test_session', 'refresher_course', 'administrative_block');
CREATE TYPE payment_method AS ENUM ('bank_transfer', 'cash', 'card', 'paypal', 'lesson_tracker_pro', 'cheque', 'online');
CREATE TYPE transaction_type AS ENUM ('income', 'expense');
CREATE TYPE expense_category AS ENUM ('accounts','advertising','association','bank_charges','computer','dvsa_fees','equipment','food_drink','franchise_fee','fuel','insurance_business','insurance_personal','insurance_vehicle','insurance','maintenance','lease','training','other');
CREATE TYPE enquiry_status AS ENUM ('pending','contacted','interested','not_interested','converted');
CREATE TYPE test_result AS ENUM ('pending','pass','fail');
CREATE TYPE message_status AS ENUM ('sending','sent','delivered','seen');
CREATE TYPE subscription_status AS ENUM ('active','cancelled','expired','trial');
CREATE TYPE invitation_status AS ENUM ('pending','approved','accepted','declined');

-- PART 2: TABLES
CREATE TABLE profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name TEXT NOT NULL DEFAULT '',
  email TEXT NOT NULL DEFAULT '',
  phone TEXT NOT NULL DEFAULT '',
  avatar_url TEXT,
  business_name TEXT DEFAULT '',
  role TEXT NOT NULL DEFAULT 'instructor' CHECK (role IN ('instructor','pupil','admin')),
  email_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE subscription_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  price DECIMAL(10,2) NOT NULL DEFAULT 0,
  duration_months INT NOT NULL DEFAULT 1,
  features JSONB DEFAULT '[]',
  is_free_tier BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE instructor_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  plan_id UUID REFERENCES subscription_plans(id),
  plan_type TEXT DEFAULT '',
  amount DECIMAL(10,2) DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'trial',
  payment_status TEXT DEFAULT 'pending',
  start_date TIMESTAMPTZ NOT NULL DEFAULT now(),
  end_date TIMESTAMPTZ,
  trial_end_date TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE pupils (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid() REFERENCES profiles(id) ON DELETE CASCADE,
  instructor_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  first_name TEXT NOT NULL DEFAULT '',
  last_name TEXT NOT NULL DEFAULT '',
  phone TEXT NOT NULL DEFAULT '',
  secondary_phone TEXT,
  email TEXT NOT NULL DEFAULT '',
  postcode TEXT,
  address TEXT,
  pickup_addresses JSONB DEFAULT '[]',
  dropoff_address TEXT,
  dropoff_addresses JSONB DEFAULT '[]',
  assigned_postcode TEXT,
  assigned_billing_rate_id TEXT,
  hourly_rate DECIMAL(10,2) NOT NULL DEFAULT 40,
  mechanical_gearbox_preference TEXT NOT NULL DEFAULT 'manual',
  gearbox_preference TEXT DEFAULT 'any',
  status TEXT NOT NULL DEFAULT 'current',
  tags JSONB DEFAULT '[]',
  availability JSONB DEFAULT '{}',
  weekly_availability JSONB DEFAULT '[]',
  weekly_availability_days JSONB DEFAULT '[]',
  notes TEXT,
  on_waiting_list BOOLEAN DEFAULT false,
  invite_to_app BOOLEAN DEFAULT false,
  terms_accepted BOOLEAN DEFAULT false,
  require_signature_before_booking BOOLEAN DEFAULT false,
  aggregated_total_lessons_count INT DEFAULT 0,
  gross_revenue_earned DECIMAL(10,2) DEFAULT 0,
  package_time_prepaid_minutes INT DEFAULT 0,
  package_time_remaining_minutes INT DEFAULT 0,
  companion_app_linked_status BOOLEAN DEFAULT false,
  outstanding_balance DECIMAL(10,2) DEFAULT 0,
  progress_scores JSONB DEFAULT '{}',
  progress_scale_type INT DEFAULT 5,
  test_date DATE,
  test_passed BOOLEAN,
  test_progress TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  registration_timestamp BIGINT DEFAULT 0
);

CREATE TABLE instructor_pupil_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  pupil_id UUID NOT NULL REFERENCES pupils(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'active',
  linked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(instructor_id, pupil_id)
);

CREATE TABLE pupil_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  postcode TEXT,
  invitation_code TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  source TEXT DEFAULT 'manual',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  accepted_at TIMESTAMPTZ
);

CREATE TABLE pupil_invite_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  token TEXT UNIQUE NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE pupil_invite_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  link_id UUID REFERENCES pupil_invite_links(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL DEFAULT '',
  phone TEXT NOT NULL DEFAULT '',
  email TEXT NOT NULL DEFAULT '',
  status TEXT DEFAULT 'pending',
  reviewed_at TIMESTAMPTZ,
  review_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE lessons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pupil_id UUID NOT NULL REFERENCES pupils(id) ON DELETE CASCADE,
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT,
  date DATE NOT NULL,
  start_time TEXT,
  end_time TEXT,
  duration_min INT DEFAULT 60,
  status TEXT NOT NULL DEFAULT 'scheduled',
  lesson_type TEXT DEFAULT 'driving_lesson',
  pickup_address TEXT,
  dropoff_address TEXT,
  price DECIMAL(10,2),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE calendar_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  pupil_id UUID REFERENCES pupils(id),
  title TEXT NOT NULL,
  description TEXT,
  date DATE NOT NULL,
  start_time TEXT,
  end_time TEXT,
  event_type TEXT DEFAULT 'lesson',
  color TEXT,
  is_completed BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE events (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  event_date TEXT,
  is_published BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  pupil_id UUID REFERENCES pupils(id),
  type TEXT NOT NULL DEFAULT 'income',
  amount DECIMAL(10,2) NOT NULL,
  category TEXT,
  description TEXT,
  date DATE NOT NULL,
  payment_method TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  pupil_id UUID NOT NULL REFERENCES pupils(id),
  amount DECIMAL(10,2) NOT NULL,
  status TEXT DEFAULT 'pending',
  due_date DATE,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES profiles(id),
  receiver_id UUID NOT NULL REFERENCES profiles(id),
  body TEXT NOT NULL,
  status TEXT DEFAULT 'sent',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE app_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT,
  type TEXT,
  is_read BOOLEAN DEFAULT false,
  data JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE enquiries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  email TEXT,
  postcode TEXT,
  notes TEXT,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE test_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pupil_id UUID NOT NULL REFERENCES pupils(id) ON DELETE CASCADE,
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  test_date DATE NOT NULL,
  result TEXT DEFAULT 'pending',
  examiner TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE mileage_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  miles DECIMAL(10,2) NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  registration TEXT,
  make TEXT,
  model TEXT,
  year INT,
  color TEXT,
  is_automatic BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE progress_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE progress_skills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID NOT NULL REFERENCES progress_categories(id) ON DELETE CASCADE,
  pupil_id UUID NOT NULL REFERENCES pupils(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  score INT DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE teaching_resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  type TEXT DEFAULT 'document',
  category TEXT,
  description TEXT,
  video_link TEXT,
  resource_link TEXT,
  share_link TEXT,
  visibility TEXT DEFAULT 'private',
  selected_pupil_ids JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE instructor_activity_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  details JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE promo_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  discount_percent INT DEFAULT 0,
  max_uses INT,
  max_uses_per_user INT,
  assigned_user_id TEXT,
  valid_until TEXT,
  is_active BOOLEAN DEFAULT true,
  used_count INT DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE banners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  link_url TEXT,
  is_active BOOLEAN DEFAULT true,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE app_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT UNIQUE NOT NULL,
  value TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE instructor_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  latitude DECIMAL(10,7),
  longitude DECIMAL(10,7),
  address TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE instructor_payment_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  status TEXT DEFAULT 'pending',
  notes TEXT,
  reviewed_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE instructor_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  payment_date TIMESTAMPTZ NOT NULL DEFAULT now(),
  status TEXT DEFAULT 'pending',
  payment_method TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  pupil_id UUID REFERENCES pupils(id),
  amount DECIMAL(10,2) NOT NULL,
  payment_date TIMESTAMPTZ NOT NULL DEFAULT now(),
  payment_method TEXT,
  status TEXT DEFAULT 'pending',
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  category TEXT,
  description TEXT,
  date DATE NOT NULL,
  receipt_url TEXT,
  is_recurring BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id),
  message TEXT NOT NULL,
  rating INT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE app_content (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- PART 3: INDEXES
CREATE INDEX idx_pupils_instructor ON pupils(instructor_id);
CREATE INDEX idx_pupil_links_instructor ON instructor_pupil_links(instructor_id);
CREATE INDEX idx_pupil_links_pupil ON instructor_pupil_links(pupil_id);
CREATE INDEX idx_lessons_instructor ON lessons(instructor_id);
CREATE INDEX idx_lessons_pupil ON lessons(pupil_id);
CREATE INDEX idx_calendar_events_instructor ON calendar_events(instructor_id);
CREATE INDEX idx_pupil_invitations_email ON pupil_invitations(email);
CREATE INDEX idx_invite_links_token ON pupil_invite_links(token);

-- PART 4: AUTO-UPDATE TRIGGER
CREATE OR REPLACE FUNCTION update_updated_at() RETURNS TRIGGER AS BEGIN NEW.updated_at = now(); RETURN NEW; END; LANGUAGE plpgsql;
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_pupils_updated_at BEFORE UPDATE ON pupils FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_lessons_updated_at BEFORE UPDATE ON lessons FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_calendar_events_updated_at BEFORE UPDATE ON calendar_events FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_vehicles_updated_at BEFORE UPDATE ON vehicles FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_progress_skills_updated_at BEFORE UPDATE ON progress_skills FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- PART 5: RLS + GRANTS (all at end, after tables exist)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructor_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE pupils ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructor_pupil_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE pupil_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE pupil_invite_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE pupil_invite_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE enquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE test_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE mileage_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE progress_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE progress_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE teaching_resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructor_activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE promo_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructor_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructor_payment_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructor_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_content ENABLE ROW LEVEL SECURITY;

-- Helper function (SECURITY DEFINER to avoid recursion)
CREATE OR REPLACE FUNCTION public.is_admin() RETURNS BOOLEAN
LANGUAGE sql SECURITY DEFINER SET search_path = public STABLE
AS SELECT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin');

-- PROFILES
CREATE POLICY "profiles_insert" ON profiles FOR INSERT WITH CHECK (true);
CREATE POLICY "profiles_read_own" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "profiles_update_own" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "profiles_admin_all" ON profiles FOR ALL USING (public.is_admin());

-- PUPILS
CREATE POLICY "pupils_insert" ON pupils FOR INSERT WITH CHECK (true);
CREATE POLICY "pupils_instructor_all" ON pupils FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "pupils_read_own" ON pupils FOR SELECT USING (id = auth.uid());
CREATE POLICY "pupils_admin_all" ON pupils FOR ALL USING (public.is_admin());

-- INSTRUCTOR PUPIL LINKS
CREATE POLICY "links_insert" ON instructor_pupil_links FOR INSERT WITH CHECK (true);
CREATE POLICY "links_instructor_all" ON instructor_pupil_links FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "links_pupil_read" ON instructor_pupil_links FOR SELECT USING (pupil_id = auth.uid());

-- All other tables: instructor owns their data, admins see all
CREATE POLICY "own_instructor_all" ON instructor_subscriptions FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "admin_all" ON instructor_subscriptions FOR ALL USING (public.is_admin());

CREATE POLICY "own_instructor_all" ON open_slots FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "own_instructor_all" ON calendar_events FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "own_instructor_all" ON transactions FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "own_instructor_all" ON invoices FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "own_instructor_all" ON enquiries FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "own_instructor_all" ON test_reports FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "own_instructor_all" ON mileage_entries FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "own_instructor_all" ON vehicles FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "own_instructor_all" ON progress_categories FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "own_instructor_all" ON teaching_resources FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "own_instructor_all" ON instructor_activity_logs FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "own_instructor_all" ON instructor_locations FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "own_instructor_all" ON instructor_payment_requests FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "own_instructor_all" ON instructor_payments FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "own_instructor_all" ON payments FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "own_instructor_all" ON expenses FOR ALL USING (instructor_id = auth.uid());

CREATE POLICY "own_instructor_all" ON pupil_invitations FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "own_instructor_all" ON pupil_invite_links FOR ALL USING (instructor_id = auth.uid());

CREATE POLICY "pupil_read_own" ON lessons FOR SELECT USING (pupil_id = auth.uid());
CREATE POLICY "pupil_read_own" ON invoices FOR SELECT USING (pupil_id = auth.uid());
CREATE POLICY "pupil_read_own" ON test_reports FOR SELECT USING (pupil_id = auth.uid());
CREATE POLICY "pupil_read_own" ON payments FOR SELECT USING (pupil_id = auth.uid());

CREATE POLICY "messages_participant" ON messages FOR ALL USING (auth.uid() IN (sender_id, receiver_id));
CREATE POLICY "notifications_user" ON app_notifications FOR ALL USING (user_id = auth.uid());
CREATE POLICY "progress_skills_instructor" ON progress_skills FOR ALL USING (category_id IN (SELECT id FROM progress_categories WHERE instructor_id = auth.uid()));
CREATE POLICY "progress_skills_pupil_read" ON progress_skills FOR SELECT USING (pupil_id = auth.uid());

CREATE POLICY "invite_submissions_insert" ON pupil_invite_submissions FOR INSERT WITH CHECK (true);
CREATE POLICY "plans_read_all" ON subscription_plans FOR SELECT USING (true);
CREATE POLICY "banners_read_all" ON banners FOR SELECT USING (true);
CREATE POLICY "app_settings_read_all" ON app_settings FOR SELECT USING (true);
CREATE POLICY "app_content_read" ON app_content FOR SELECT USING (true);

CREATE POLICY "admin_all" ON subscription_plans FOR ALL USING (public.is_admin());
CREATE POLICY "admin_all" ON promo_codes FOR ALL USING (public.is_admin());
CREATE POLICY "admin_all" ON banners FOR ALL USING (public.is_admin());
CREATE POLICY "admin_all" ON app_settings FOR ALL USING (public.is_admin());
CREATE POLICY "admin_all" ON events FOR ALL USING (public.is_admin());
CREATE POLICY "admin_all" ON instructor_payment_requests FOR ALL USING (public.is_admin());
CREATE POLICY "admin_all" ON instructor_payments FOR ALL USING (public.is_admin());
CREATE POLICY "admin_all" ON payments FOR ALL USING (public.is_admin());
CREATE POLICY "admin_all" ON feedback FOR ALL USING (public.is_admin());
CREATE POLICY "admin_all" ON app_content FOR ALL USING (public.is_admin());

CREATE POLICY "events_public_read" ON events FOR SELECT USING (is_published = true);
CREATE POLICY "feedback_insert" ON feedback FOR INSERT WITH CHECK (true);

-- GRANTS (runs AFTER all tables exist)
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

-- PART 6: AUTH TRIGGER
CREATE OR REPLACE FUNCTION public.handle_new_user() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS
BEGIN
  INSERT INTO public.profiles (id, full_name, email, phone, role, email_verified)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'full_name', ''), COALESCE(NEW.email, ''), COALESCE(NEW.raw_user_meta_data->>'phone', ''), COALESCE(NEW.raw_user_meta_data->>'role', 'instructor'), FALSE);
  RETURN NEW;
END;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- PART 7: SEED DATA
INSERT INTO subscription_plans (name, price, duration_months, features, is_free_tier, is_active, sort_order) VALUES
  ('Free Trial', 0, 2, '["Up to 5 pupils", "Basic diary", "Manual payment tracking"]', true, true, 0),
  ('Starter', 9.99, 1, '["Up to 10 pupils", "Smart diary", "Payment tracking", "Pupil messaging"]', false, true, 1),
  ('Professional', 19.99, 1, '["Unlimited pupils", "Smart diary with slots", "Full financial reports", "Pupil messaging & portal", "Progress tracking", "Test reports"]', false, true, 2),
  ('Premium', 29.99, 1, '["Everything in Professional", "Online booking", "Route planning", "Priority support", "Custom branding", "API access"]', false, true, 3);

INSERT INTO app_settings (key, value) VALUES
  ('platform_name', '"Lesson Tracker Pro"'), ('platform_fee_percentage', '2.9'), ('free_trial_days', '60'), ('default_currency', '"GBP"'), ('support_email', '"support@lessontrackerpro.com"');

INSERT INTO banners (title, description, is_active, sort_order) VALUES
  ('Welcome to Lesson Tracker Pro', 'Your all-in-one driving school management platform', true, 0);

-- SCHEMA COMPLETE
