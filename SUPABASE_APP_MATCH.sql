-- =============================================================
-- LESSON TRACKER PRO - APP-MATCHED SCHEMA  (v2.0)
-- Every column matches the Flutter app code EXACTLY.
-- Run in Supabase SQL Editor on a CLEAN database.
-- =============================================================

-- 0. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. ENUMS
DO $$ BEGIN
  CREATE TYPE pupil_status AS ENUM ('current','waiting','passed','archived','cancelled');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE gearbox_type AS ENUM ('any','manual','automatic');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE lesson_status AS ENUM ('scheduled','completed','cancelled','no_show');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE lesson_type AS ENUM ('driving_lesson','mock_test_session','refresher_course','administrative_block');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE enrolment_status AS ENUM ('pending','approved','accepted','declined');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 2. TABLES

-- App settings (key-value)
CREATE TABLE IF NOT EXISTS app_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT UNIQUE NOT NULL,
  value TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Static content pages (terms, privacy)
CREATE TABLE IF NOT EXISTS app_content (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL DEFAULT '',
  content TEXT NOT NULL DEFAULT '',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- In-app notifications
CREATE TABLE IF NOT EXISTS app_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  title TEXT NOT NULL DEFAULT '',
  body TEXT DEFAULT '',
  timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
  read BOOLEAN DEFAULT false,
  type TEXT DEFAULT '',
  data JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Promotional banners
CREATE TABLE IF NOT EXISTS banners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL DEFAULT '',
  description TEXT DEFAULT '',
  image_url TEXT DEFAULT '',
  link_url TEXT DEFAULT '',
  is_active BOOLEAN DEFAULT true,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Calendar events (personal events on the diary)
CREATE TABLE IF NOT EXISTS calendar_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL,
  pupil_id UUID,
  title TEXT NOT NULL DEFAULT '',
  description TEXT DEFAULT '',
  location TEXT DEFAULT '',
  event_date TEXT DEFAULT '',
  event_time TEXT DEFAULT '',
  is_all_day BOOLEAN DEFAULT false,
  time TEXT DEFAULT '',
  date TEXT DEFAULT '',
  notes TEXT DEFAULT '',
  end_date TEXT DEFAULT '',
  end_time TEXT DEFAULT '',
  sync_to_external_calendar BOOLEAN DEFAULT false,
  completed BOOLEAN DEFAULT false,
  color TEXT DEFAULT '',
  event_type TEXT DEFAULT 'lesson',
  is_completed BOOLEAN DEFAULT false,
  start_date TEXT DEFAULT '',
  start_time TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- Admin-created events (public / published)
CREATE TABLE IF NOT EXISTS events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL DEFAULT '',
  description TEXT DEFAULT '',
  event_date TEXT DEFAULT '',
  is_published BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enquiries (instructor leads)
CREATE TABLE IF NOT EXISTS enquiries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID,
  instructor_name TEXT DEFAULT '',
  instructor_email TEXT DEFAULT '',
  instructor_phone TEXT DEFAULT '',
  pupil_id UUID,
  first_name TEXT DEFAULT '',
  last_name TEXT DEFAULT '',
  email TEXT DEFAULT '',
  phone TEXT DEFAULT '',
  address TEXT DEFAULT '',
  postcode TEXT DEFAULT '',
  notes TEXT DEFAULT '',
  message TEXT DEFAULT '',
  experience_level TEXT DEFAULT '',
  gearbox_preference TEXT DEFAULT '',
  has_provisional_license BOOLEAN DEFAULT false,
  prior_practice_hours INT DEFAULT 0,
  weekly_availability TEXT DEFAULT '',
  status TEXT DEFAULT 'pending',
  assigned_to_id UUID,
  isMockData BOOLEAN DEFAULT false,
  source TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Expense entries (snake_case for sync service)
CREATE TABLE IF NOT EXISTS expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID,
  type TEXT DEFAULT 'expense',
  amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  description TEXT DEFAULT '',
  date TEXT DEFAULT '',
  pupil_id UUID,
  pupil_name TEXT DEFAULT '',
  payment_method TEXT DEFAULT '',
  payment_type TEXT DEFAULT '',
  category TEXT DEFAULT '',
  is_recurring BOOLEAN DEFAULT false,
  receipt_url TEXT DEFAULT '',
  vendor_name TEXT DEFAULT '',
  is_reconciled BOOLEAN DEFAULT false,
  tax_deductible BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- User feedback
CREATE TABLE IF NOT EXISTS feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  type TEXT DEFAULT '',
  rating INT DEFAULT 0,
  message TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Instructor activity logs
CREATE TABLE IF NOT EXISTS instructor_activity_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL,
  action TEXT NOT NULL DEFAULT '',
  details JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Instructor locations (GPS)
CREATE TABLE IF NOT EXISTS instructor_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL,
  latitude DECIMAL(10,7),
  longitude DECIMAL(10,7),
  address TEXT DEFAULT '',
  timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Instructor payment requests
CREATE TABLE IF NOT EXISTS instructor_payment_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL,
  pupil_id UUID,
  amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  description TEXT DEFAULT '',
  status TEXT DEFAULT 'pending',
  request_date TIMESTAMPTZ NOT NULL DEFAULT now(),
  processed_date TIMESTAMPTZ,
  notes TEXT DEFAULT '',
  reviewed_by UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Instructor payments (income records, sync-service compatible)
CREATE TABLE IF NOT EXISTS instructor_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID,
  pupil_id UUID,
  pupil_name TEXT DEFAULT '',
  type TEXT DEFAULT 'income',
  amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  description TEXT DEFAULT '',
  date TEXT DEFAULT '',
  payment_method TEXT DEFAULT '',
  payment_type TEXT DEFAULT '',
  category TEXT DEFAULT '',
  is_recurring BOOLEAN DEFAULT false,
  receipt_url TEXT DEFAULT '',
  vendor_name TEXT DEFAULT '',
  is_reconciled BOOLEAN DEFAULT false,
  tax_deductible BOOLEAN DEFAULT true,
  status TEXT DEFAULT 'pending',
  payment_date TIMESTAMPTZ NOT NULL DEFAULT now(),
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- Pupil-instructor links
CREATE TABLE IF NOT EXISTS instructor_pupil_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL,
  pupil_id UUID NOT NULL,
  status TEXT DEFAULT 'active',
  linked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(instructor_id, pupil_id)
);

-- Instructor subscriptions
CREATE TABLE IF NOT EXISTS instructor_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL,
  plan_id UUID,
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

-- Instructor extras table (FK to profiles.id)
CREATE TABLE IF NOT EXISTS instructors (
  id UUID PRIMARY KEY,
  phone TEXT DEFAULT '',
  is_verified BOOLEAN DEFAULT false,
  rating DECIMAL(3,2) DEFAULT 0,
  hourly_rate DECIMAL(10,2) DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Invoices
CREATE TABLE IF NOT EXISTS invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID,
  pupil_id UUID,
  amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  status TEXT DEFAULT 'pending',
  due_date TEXT DEFAULT '',
  description TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Driving lessons
CREATE TABLE IF NOT EXISTS lessons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL,
  pupil_id UUID NOT NULL,
  pupil_name TEXT DEFAULT '',
  title TEXT DEFAULT '',
  date TEXT DEFAULT '',
  time TEXT DEFAULT '',
  duration INT DEFAULT 60,
  type TEXT DEFAULT 'driving_lesson',
  status TEXT DEFAULT 'scheduled',
  rate DECIMAL(10,2) DEFAULT 0,
  paid BOOLEAN DEFAULT false,
  pickup_location TEXT DEFAULT '',
  dropoff_location TEXT DEFAULT '',
  pickup_address TEXT DEFAULT '',
  dropoff_address TEXT DEFAULT '',
  notes TEXT DEFAULT '',
  is_recurring BOOLEAN DEFAULT false,
  shared_with_pupil BOOLEAN DEFAULT false,
  require_online_payment BOOLEAN DEFAULT false,
  session_classification TEXT DEFAULT 'driving_lesson',
  booking_status TEXT DEFAULT 'confirmed',
  is_shared_with_pupil_companion_view BOOLEAN DEFAULT false,
  start_time TEXT DEFAULT '',
  end_time TEXT DEFAULT '',
  duration_min INT DEFAULT 60,
  price DECIMAL(10,2) DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Messages (chat)
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL,
  receiver_id UUID NOT NULL,
  pupil_id UUID,
  pupil_name TEXT DEFAULT '',
  body TEXT NOT NULL DEFAULT '',
  content TEXT DEFAULT '',
  timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_from_instructor BOOLEAN DEFAULT false,
  status TEXT DEFAULT 'sent',
  is_locked BOOLEAN DEFAULT false,
  is_edited BOOLEAN DEFAULT false,
  is_deleted BOOLEAN DEFAULT false,
  scheduled_for TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- Mileage entries
CREATE TABLE IF NOT EXISTS mileage_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL,
  date TEXT DEFAULT '',
  start_mileage DECIMAL(10,2) DEFAULT 0,
  end_mileage DECIMAL(10,2) DEFAULT 0,
  miles DECIMAL(10,2) NOT NULL DEFAULT 0,
  type TEXT DEFAULT '',
  notes TEXT DEFAULT '',
  description TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Open slots (diary availability)
CREATE TABLE IF NOT EXISTS open_slots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL,
  date TEXT DEFAULT '',
  start_time TEXT DEFAULT '',
  duration INT DEFAULT 60,
  is_recurring BOOLEAN DEFAULT false,
  recurrence_type TEXT DEFAULT '',
  accepts_online_payment BOOLEAN DEFAULT false,
  group_filter TEXT DEFAULT 'currentPupilsOnly',
  gearbox_filter TEXT DEFAULT 'any',
  target_pupil_ids JSONB DEFAULT '[]',
  custom_message TEXT DEFAULT '',
  slot_count INT DEFAULT 1,
  status TEXT DEFAULT 'available',
  offered_to_pupil_id TEXT DEFAULT '',
  is_booked BOOLEAN DEFAULT false,
  booked_by UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Payments
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL,
  pupil_id UUID,
  lesson_id UUID,
  type TEXT DEFAULT 'income',
  amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  description TEXT DEFAULT '',
  payment_method TEXT DEFAULT '',
  status TEXT DEFAULT 'pending',
  payment_date TIMESTAMPTZ NOT NULL DEFAULT now(),
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Profiles (users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name TEXT NOT NULL DEFAULT '',
  email TEXT NOT NULL DEFAULT '',
  phone TEXT NOT NULL DEFAULT '',
  avatar_url TEXT DEFAULT '',
  business_name TEXT DEFAULT '',
  role TEXT NOT NULL DEFAULT 'instructor' CHECK (role IN ('instructor','pupil','admin')),
  email_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Progress categories
CREATE TABLE IF NOT EXISTS progress_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL,
  title TEXT NOT NULL DEFAULT '',
  description TEXT DEFAULT '',
  name TEXT DEFAULT '',
  order_index INT DEFAULT 0,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Progress skills
CREATE TABLE IF NOT EXISTS progress_skills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID NOT NULL,
  pupil_id UUID NOT NULL,
  title TEXT NOT NULL DEFAULT '',
  description TEXT DEFAULT '',
  name TEXT DEFAULT '',
  order_index INT DEFAULT 0,
  score INT DEFAULT 0,
  requires_independent_driving BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Promo codes
CREATE TABLE IF NOT EXISTS promo_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  discount_percent INT DEFAULT 0,
  max_uses INT DEFAULT 0,
  max_uses_per_user INT DEFAULT 0,
  assigned_user_id TEXT DEFAULT '',
  valid_until TEXT DEFAULT '',
  is_active BOOLEAN DEFAULT true,
  used_count INT DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Pupil invitations (invite via email)
CREATE TABLE IF NOT EXISTS pupil_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL,
  email TEXT NOT NULL DEFAULT '',
  first_name TEXT DEFAULT '',
  last_name TEXT DEFAULT '',
  phone TEXT DEFAULT '',
  postcode TEXT DEFAULT '',
  invitation_code TEXT DEFAULT '',
  status TEXT DEFAULT 'pending',
  source TEXT DEFAULT 'manual',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  accepted_at TIMESTAMPTZ
);
-- Pupil invite links (shareable link)
CREATE TABLE IF NOT EXISTS pupil_invite_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL,
  token TEXT UNIQUE NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Submissions via invite link
CREATE TABLE IF NOT EXISTS pupil_invite_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  link_id UUID,
  full_name TEXT NOT NULL DEFAULT '',
  phone TEXT NOT NULL DEFAULT '',
  email TEXT NOT NULL DEFAULT '',
  status TEXT DEFAULT 'pending',
  reviewed_at TIMESTAMPTZ,
  review_notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Pupils (students)
CREATE TABLE IF NOT EXISTS pupils (
  id UUID PRIMARY KEY,
  instructor_id UUID,
  first_name TEXT NOT NULL DEFAULT '',
  last_name TEXT NOT NULL DEFAULT '',
  phone TEXT NOT NULL DEFAULT '',
  secondary_phone TEXT DEFAULT '',
  email TEXT NOT NULL DEFAULT '',
  postcode TEXT DEFAULT '',
  address TEXT DEFAULT '',
  dropoff_address TEXT DEFAULT '',
  notes TEXT DEFAULT '',
  weekly_availability TEXT DEFAULT '',
  gearbox_preference TEXT DEFAULT 'any',
  hourly_rate DECIMAL(10,2) NOT NULL DEFAULT 40,
  mechanical_gearbox_preference TEXT DEFAULT 'manual',
  status TEXT DEFAULT 'current',
  tags JSONB DEFAULT '[]',
  availability JSONB DEFAULT '{}',
  weekly_availability_days JSONB DEFAULT '[]',
  pickup_addresses JSONB DEFAULT '[]',
  dropoff_addresses JSONB DEFAULT '[]',
  assigned_postcode TEXT DEFAULT '',
  assigned_billing_rate_id TEXT DEFAULT '',
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
  test_date TEXT DEFAULT '',
  test_passed BOOLEAN,
  test_progress TEXT DEFAULT '',
  registration_timestamp BIGINT DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Subscription plans
CREATE TABLE IF NOT EXISTS subscription_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL DEFAULT '',
  price DECIMAL(10,2) NOT NULL DEFAULT 0,
  duration_months INT NOT NULL DEFAULT 1,
  features JSONB DEFAULT '[]',
  is_free_tier BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Teaching resources
CREATE TABLE IF NOT EXISTS teaching_resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL,
  title TEXT NOT NULL DEFAULT '',
  type TEXT DEFAULT 'document',
  category TEXT DEFAULT '',
  description TEXT DEFAULT '',
  video_link TEXT DEFAULT '',
  resource_link TEXT DEFAULT '',
  share_link TEXT DEFAULT '',
  visibility TEXT DEFAULT 'private',
  selected_pupil_ids JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Test reports
CREATE TABLE IF NOT EXISTS test_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL,
  pupil_id UUID NOT NULL,
  pupil_name TEXT DEFAULT '',
  test_date TEXT DEFAULT '',
  test_center_id INT DEFAULT 0,
  test_center_name TEXT DEFAULT '',
  grade_level TEXT DEFAULT 'Practical',
  result TEXT DEFAULT 'pending',
  manoeuvres JSONB DEFAULT '[]',
  scales_notes TEXT DEFAULT '',
  aural_notes TEXT DEFAULT '',
  notes TEXT DEFAULT '',
  faults INT DEFAULT 0,
  serious_faults INT DEFAULT 0,
  dangerous_faults INT DEFAULT 0,
  examiner_name TEXT DEFAULT '',
  examiner TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Transactions (generic, used by mileage_dialog)
CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL,
  type TEXT DEFAULT 'income',
  amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  description TEXT DEFAULT '',
  date TEXT DEFAULT '',
  category TEXT DEFAULT '',
  payment_method TEXT DEFAULT '',
  pupil_id UUID,
  pupil_name TEXT DEFAULT '',
  payment_type TEXT DEFAULT '',
  is_recurring BOOLEAN DEFAULT false,
  receipt_url TEXT DEFAULT '',
  vendor_name TEXT DEFAULT '',
  is_reconciled BOOLEAN DEFAULT false,
  tax_deductible BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Vehicles
CREATE TABLE IF NOT EXISTS vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL,
  make TEXT DEFAULT '',
  model TEXT DEFAULT '',
  plate TEXT DEFAULT '',
  registration TEXT DEFAULT '',
  name TEXT DEFAULT '',
  year INT DEFAULT 0,
  color TEXT DEFAULT '',
  notes TEXT DEFAULT '',
  is_primary BOOLEAN DEFAULT false,
  gearbox TEXT DEFAULT 'manual',
  mot_expiry_date TEXT DEFAULT '',
  tax_expiry_date TEXT DEFAULT '',
  insurance_expiry_date TEXT DEFAULT '',
  last_service_date TEXT DEFAULT '',
  current_mileage INT DEFAULT 0,
  is_automatic BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- 3. FOREIGN KEYS
ALTER TABLE ONLY app_notifications ADD CONSTRAINT app_notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY calendar_events ADD CONSTRAINT calendar_events_instructor_id_fkey FOREIGN KEY (instructor_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY enquiries ADD CONSTRAINT enquiries_instructor_id_fkey FOREIGN KEY (instructor_id) REFERENCES instructors(id) ON DELETE SET NULL;
ALTER TABLE ONLY enquiries ADD CONSTRAINT enquiries_pupil_id_fkey FOREIGN KEY (pupil_id) REFERENCES pupils(id) ON DELETE SET NULL;
ALTER TABLE ONLY expenses ADD CONSTRAINT expenses_instructor_id_fkey FOREIGN KEY (instructor_id) REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE ONLY feedback ADD CONSTRAINT feedback_user_id_fkey FOREIGN KEY (user_id) REFERENCES profiles(id);
ALTER TABLE ONLY instructor_activity_logs ADD CONSTRAINT instructor_activity_logs_instructor_id_fkey FOREIGN KEY (instructor_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY instructor_locations ADD CONSTRAINT instructor_locations_instructor_id_fkey FOREIGN KEY (instructor_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY instructor_payment_requests ADD CONSTRAINT instructor_payment_requests_instructor_id_fkey FOREIGN KEY (instructor_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY instructor_payments ADD CONSTRAINT instructor_payments_instructor_id_fkey FOREIGN KEY (instructor_id) REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE ONLY instructor_pupil_links ADD CONSTRAINT instructor_pupil_links_instructor_id_fkey FOREIGN KEY (instructor_id) REFERENCES instructors(id) ON DELETE CASCADE;
ALTER TABLE ONLY instructor_pupil_links ADD CONSTRAINT instructor_pupil_links_pupil_id_fkey FOREIGN KEY (pupil_id) REFERENCES pupils(id) ON DELETE CASCADE;
ALTER TABLE ONLY instructor_subscriptions ADD CONSTRAINT instructor_subscriptions_instructor_id_fkey FOREIGN KEY (instructor_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY instructors ADD CONSTRAINT instructors_id_fkey FOREIGN KEY (id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY invoices ADD CONSTRAINT invoices_instructor_id_fkey FOREIGN KEY (instructor_id) REFERENCES instructors(id) ON DELETE SET NULL;
ALTER TABLE ONLY invoices ADD CONSTRAINT invoices_pupil_id_fkey FOREIGN KEY (pupil_id) REFERENCES pupils(id) ON DELETE SET NULL;
ALTER TABLE ONLY lessons ADD CONSTRAINT lessons_instructor_id_fkey FOREIGN KEY (instructor_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY lessons ADD CONSTRAINT lessons_pupil_id_fkey FOREIGN KEY (pupil_id) REFERENCES pupils(id) ON DELETE CASCADE;
ALTER TABLE ONLY messages ADD CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES profiles(id);
ALTER TABLE ONLY messages ADD CONSTRAINT messages_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES profiles(id);
ALTER TABLE ONLY mileage_entries ADD CONSTRAINT mileage_entries_instructor_id_fkey FOREIGN KEY (instructor_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY open_slots ADD CONSTRAINT open_slots_instructor_id_fkey FOREIGN KEY (instructor_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY payments ADD CONSTRAINT payments_instructor_id_fkey FOREIGN KEY (instructor_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY payments ADD CONSTRAINT payments_pupil_id_fkey FOREIGN KEY (pupil_id) REFERENCES pupils(id) ON DELETE SET NULL;
ALTER TABLE ONLY progress_categories ADD CONSTRAINT progress_categories_instructor_id_fkey FOREIGN KEY (instructor_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY progress_skills ADD CONSTRAINT progress_skills_pupil_id_fkey FOREIGN KEY (pupil_id) REFERENCES pupils(id) ON DELETE CASCADE;
ALTER TABLE ONLY pupil_invitations ADD CONSTRAINT pupil_invitations_instructor_id_fkey FOREIGN KEY (instructor_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY pupil_invite_links ADD CONSTRAINT pupil_invite_links_instructor_id_fkey FOREIGN KEY (instructor_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY pupil_invite_submissions ADD CONSTRAINT pupil_invite_submissions_link_id_fkey FOREIGN KEY (link_id) REFERENCES pupil_invite_links(id) ON DELETE CASCADE;
ALTER TABLE ONLY pupils ADD CONSTRAINT pupils_id_fkey FOREIGN KEY (id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY pupils ADD CONSTRAINT pupils_instructor_id_fkey FOREIGN KEY (instructor_id) REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE ONLY teaching_resources ADD CONSTRAINT teaching_resources_instructor_id_fkey FOREIGN KEY (instructor_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY test_reports ADD CONSTRAINT test_reports_instructor_id_fkey FOREIGN KEY (instructor_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY test_reports ADD CONSTRAINT test_reports_pupil_id_fkey FOREIGN KEY (pupil_id) REFERENCES pupils(id) ON DELETE CASCADE;
ALTER TABLE ONLY transactions ADD CONSTRAINT transactions_instructor_id_fkey FOREIGN KEY (instructor_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE ONLY vehicles ADD CONSTRAINT vehicles_instructor_id_fkey FOREIGN KEY (instructor_id) REFERENCES profiles(id) ON DELETE CASCADE;

-- 4. INDEXES
CREATE INDEX IF NOT EXISTS idx_calendar_events_instructor ON calendar_events(instructor_id);
CREATE INDEX IF NOT EXISTS idx_enquiries_instructor ON enquiries(instructor_id);
CREATE INDEX IF NOT EXISTS idx_instructor_pupil_links_instructor ON instructor_pupil_links(instructor_id);
CREATE INDEX IF NOT EXISTS idx_instructor_pupil_links_pupil ON instructor_pupil_links(pupil_id);
CREATE INDEX IF NOT EXISTS idx_instructor_subscriptions_instructor ON instructor_subscriptions(instructor_id);
CREATE INDEX IF NOT EXISTS idx_lessons_instructor ON lessons(instructor_id);
CREATE INDEX IF NOT EXISTS idx_lessons_pupil ON lessons(pupil_id);
CREATE INDEX IF NOT EXISTS idx_messages_participants ON messages(sender_id, receiver_id);
CREATE INDEX IF NOT EXISTS idx_open_slots_instructor ON open_slots(instructor_id);
CREATE INDEX IF NOT EXISTS idx_payments_instructor ON payments(instructor_id);
CREATE INDEX IF NOT EXISTS idx_payments_pupil ON payments(pupil_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_pupil_invitations_email ON pupil_invitations(email);
CREATE INDEX IF NOT EXISTS idx_pupil_invite_links_token ON pupil_invite_links(token);
CREATE INDEX IF NOT EXISTS idx_pupils_instructor ON pupils(instructor_id);
CREATE INDEX IF NOT EXISTS idx_test_reports_instructor ON test_reports(instructor_id);
CREATE INDEX IF NOT EXISTS idx_test_reports_pupil ON test_reports(pupil_id);
-- 5. AUTO-UPDATE TRIGGER
CREATE OR REPLACE FUNCTION update_updated_at() RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at();
DROP TRIGGER IF EXISTS update_pupils_updated_at ON pupils;
CREATE TRIGGER update_pupils_updated_at BEFORE UPDATE ON pupils FOR EACH ROW EXECUTE FUNCTION update_updated_at();
DROP TRIGGER IF EXISTS update_lessons_updated_at ON lessons;
CREATE TRIGGER update_lessons_updated_at BEFORE UPDATE ON lessons FOR EACH ROW EXECUTE FUNCTION update_updated_at();
DROP TRIGGER IF EXISTS update_calendar_events_updated_at ON calendar_events;
CREATE TRIGGER update_calendar_events_updated_at BEFORE UPDATE ON calendar_events FOR EACH ROW EXECUTE FUNCTION update_updated_at();
DROP TRIGGER IF EXISTS update_invoices_updated_at ON invoices;
CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices FOR EACH ROW EXECUTE FUNCTION update_updated_at();
DROP TRIGGER IF EXISTS update_vehicles_updated_at ON vehicles;
CREATE TRIGGER update_vehicles_updated_at BEFORE UPDATE ON vehicles FOR EACH ROW EXECUTE FUNCTION update_updated_at();
DROP TRIGGER IF EXISTS update_progress_skills_updated_at ON progress_skills;
CREATE TRIGGER update_progress_skills_updated_at BEFORE UPDATE ON progress_skills FOR EACH ROW EXECUTE FUNCTION update_updated_at();
DROP TRIGGER IF EXISTS update_app_settings_updated_at ON app_settings;
CREATE TRIGGER update_app_settings_updated_at BEFORE UPDATE ON app_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at();
DROP TRIGGER IF EXISTS update_app_content_updated_at ON app_content;
CREATE TRIGGER update_app_content_updated_at BEFORE UPDATE ON app_content FOR EACH ROW EXECUTE FUNCTION update_updated_at();
DROP TRIGGER IF EXISTS update_instructor_payment_requests_updated_at ON instructor_payment_requests;
CREATE TRIGGER update_instructor_payment_requests_updated_at BEFORE UPDATE ON instructor_payment_requests FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 6. RLS
ALTER TABLE app_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE enquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructor_activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructor_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructor_payment_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructor_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructor_pupil_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructor_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructors ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE mileage_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE open_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE progress_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE progress_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE promo_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE pupil_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE pupil_invite_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE pupil_invite_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE pupils ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE teaching_resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE test_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.is_admin() RETURNS BOOLEAN
LANGUAGE sql SECURITY DEFINER SET search_path = public STABLE
AS $$ SELECT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'); $$;

-- PROFILES
CREATE POLICY profiles_insert ON profiles FOR INSERT WITH CHECK (true);
CREATE POLICY profiles_read_own ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY profiles_read_instructor_pupils ON profiles FOR SELECT USING (
  auth.uid() IN (SELECT instructor_id FROM instructor_pupil_links WHERE pupil_id = id)
);
CREATE POLICY profiles_update_own ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY profiles_admin_all ON profiles FOR ALL USING (public.is_admin());

-- INSTRUCTORS
CREATE POLICY instructors_insert ON instructors FOR INSERT WITH CHECK (true);
CREATE POLICY instructors_read_all ON instructors FOR SELECT USING (true);
CREATE POLICY instructors_update_own ON instructors FOR UPDATE USING (id = auth.uid());
CREATE POLICY instructors_admin_all ON instructors FOR ALL USING (public.is_admin());

-- PUPILS
CREATE POLICY pupils_insert ON pupils FOR INSERT WITH CHECK (true);
CREATE POLICY pupils_instructor_all ON pupils FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY pupils_read_own ON pupils FOR SELECT USING (id = auth.uid());
CREATE POLICY pupils_admin_all ON pupils FOR ALL USING (public.is_admin());

-- LINKS
CREATE POLICY links_insert ON instructor_pupil_links FOR INSERT WITH CHECK (true);
CREATE POLICY links_instructor_all ON instructor_pupil_links FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY links_pupil_read ON instructor_pupil_links FOR SELECT USING (pupil_id = auth.uid());
CREATE POLICY links_admin_all ON instructor_pupil_links FOR ALL USING (public.is_admin());
-- OWNER POLICIES (instructor owns their data)
CREATE POLICY own_instructor_all ON instructor_subscriptions FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY own_instructor_all ON open_slots FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY own_instructor_all ON calendar_events FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY own_instructor_all ON transactions FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY own_instructor_all ON invoices FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY own_instructor_all ON enquiries FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY own_instructor_all ON test_reports FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY own_instructor_all ON mileage_entries FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY own_instructor_all ON vehicles FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY own_instructor_all ON progress_categories FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY own_instructor_all ON teaching_resources FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY own_instructor_all ON instructor_activity_logs FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY own_instructor_all ON instructor_locations FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY own_instructor_all ON instructor_payment_requests FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY own_instructor_all ON instructor_payments FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY own_instructor_all ON payments FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY own_instructor_all ON expenses FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY own_instructor_all ON pupil_invitations FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY own_instructor_all ON pupil_invite_links FOR ALL USING (instructor_id = auth.uid());

-- ADMIN POLICIES
CREATE POLICY admin_all ON instructor_subscriptions FOR ALL USING (public.is_admin());
CREATE POLICY admin_all ON open_slots FOR ALL USING (public.is_admin());
CREATE POLICY admin_all ON calendar_events FOR ALL USING (public.is_admin());
CREATE POLICY admin_all ON transactions FOR ALL USING (public.is_admin());
CREATE POLICY admin_all ON invoices FOR ALL USING (public.is_admin());
CREATE POLICY admin_all ON enquiries FOR ALL USING (public.is_admin());
CREATE POLICY admin_all ON test_reports FOR ALL USING (public.is_admin());
CREATE POLICY admin_all ON mileage_entries FOR ALL USING (public.is_admin());
CREATE POLICY admin_all ON vehicles FOR ALL USING (public.is_admin());
CREATE POLICY admin_all ON progress_categories FOR ALL USING (public.is_admin());
CREATE POLICY admin_all ON progress_skills FOR ALL USING (public.is_admin());
CREATE POLICY admin_all ON teaching_resources FOR ALL USING (public.is_admin());
CREATE POLICY admin_all ON instructor_activity_logs FOR ALL USING (public.is_admin());
CREATE POLICY admin_all ON instructor_locations FOR ALL USING (public.is_admin());
CREATE POLICY admin_all ON instructor_payment_requests FOR ALL USING (public.is_admin());
CREATE POLICY admin_all ON instructor_payments FOR ALL USING (public.is_admin());
CREATE POLICY admin_all ON payments FOR ALL USING (public.is_admin());
CREATE POLICY admin_all ON expenses FOR ALL USING (public.is_admin());
CREATE POLICY admin_all ON pupil_invitations FOR ALL USING (public.is_admin());
CREATE POLICY admin_all ON pupil_invite_links FOR ALL USING (public.is_admin());
CREATE POLICY admin_all ON pupil_invite_submissions FOR ALL USING (public.is_admin());
CREATE POLICY admin_all ON subscription_plans FOR ALL USING (public.is_admin());
CREATE POLICY admin_all ON promo_codes FOR ALL USING (public.is_admin());
CREATE POLICY admin_all ON banners FOR ALL USING (public.is_admin());
CREATE POLICY admin_all ON app_settings FOR ALL USING (public.is_admin());
CREATE POLICY admin_all ON events FOR ALL USING (public.is_admin());
CREATE POLICY admin_all ON feedback FOR ALL USING (public.is_admin());
CREATE POLICY admin_all ON app_content FOR ALL USING (public.is_admin());

-- PUPIL READ POLICIES
CREATE POLICY pupil_read_own ON lessons FOR SELECT USING (pupil_id = auth.uid());
CREATE POLICY pupil_read_own ON invoices FOR SELECT USING (pupil_id = auth.uid());
CREATE POLICY pupil_read_own ON test_reports FOR SELECT USING (pupil_id = auth.uid());
CREATE POLICY pupil_read_own ON payments FOR SELECT USING (pupil_id = auth.uid());
CREATE POLICY pupil_read_own ON progress_skills FOR SELECT USING (pupil_id = auth.uid());
CREATE POLICY pupil_read_own ON enquiries FOR SELECT USING (pupil_id = auth.uid());

-- MISC POLICIES
CREATE POLICY messages_participant ON messages FOR ALL USING (auth.uid() IN (sender_id, receiver_id));
CREATE POLICY notifications_user ON app_notifications FOR ALL USING (user_id = auth.uid());
CREATE POLICY invite_submissions_insert ON pupil_invite_submissions FOR INSERT WITH CHECK (true);
CREATE POLICY plans_read_all ON subscription_plans FOR SELECT USING (true);
CREATE POLICY banners_read_all ON banners FOR SELECT USING (true);
CREATE POLICY app_settings_read_all ON app_settings FOR SELECT USING (true);
CREATE POLICY app_content_read ON app_content FOR SELECT USING (true);
CREATE POLICY events_public_read ON events FOR SELECT USING (is_published = true);
CREATE POLICY feedback_insert ON feedback FOR INSERT WITH CHECK (true);
CREATE POLICY lessons_instructor_all ON lessons FOR ALL USING (instructor_id = auth.uid());
-- 7. GRANTS
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

-- 8. AUTH TRIGGER
CREATE OR REPLACE FUNCTION public.handle_new_user() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, phone, role, email_verified)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'full_name', ''), COALESCE(NEW.email, ''), COALESCE(NEW.raw_user_meta_data->>'phone', ''), COALESCE(NEW.raw_user_meta_data->>'role', 'instructor'), FALSE);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 9. SEED DATA
INSERT INTO subscription_plans (name, price, duration_months, features, is_free_tier, is_active, sort_order) VALUES
  ('Free Trial', 0, 2, '["Up to 5 pupils", "Basic diary", "Manual payment tracking"]', true, true, 0),
  ('Starter', 9.99, 1, '["Up to 10 pupils", "Smart diary", "Payment tracking", "Pupil messaging"]', false, true, 1),
  ('Professional', 19.99, 1, '["Unlimited pupils", "Smart diary with slots", "Full financial reports", "Pupil messaging & portal", "Progress tracking", "Test reports"]', false, true, 2),
  ('Premium', 29.99, 1, '["Everything in Professional", "Online booking", "Route planning", "Priority support", "Custom branding", "API access"]', false, true, 3)
ON CONFLICT DO NOTHING;

INSERT INTO app_settings (key, value) VALUES
  ('platform_name', '"Lesson Tracker Pro"'),
  ('platform_fee_percentage', '2.9'),
  ('free_trial_days', '60'),
  ('default_currency', '"GBP"'),
  ('support_email', '"support@lessontrackerpro.com"')
ON CONFLICT (key) DO NOTHING;

INSERT INTO banners (title, description, is_active, sort_order) VALUES
  ('Welcome to Lesson Tracker Pro', 'Your all-in-one driving school management platform', true, 0)
ON CONFLICT DO NOTHING;
