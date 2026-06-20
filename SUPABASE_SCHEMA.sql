-- =============================================================
-- LESSON TRACKER PRO - COMPLETE DATABASE SCHEMA
-- Supabase PostgreSQL Production Schema
-- Run this entire file in Supabase SQL Editor
-- =============================================================

-- =============================================================
-- PART 1: ENUMS
-- =============================================================

CREATE TYPE pupil_status AS ENUM ('current', 'waiting', 'passed', 'archived', 'cancelled');
CREATE TYPE gearbox_type AS ENUM ('any', 'manual', 'automatic');
CREATE TYPE lesson_status AS ENUM ('scheduled', 'completed', 'cancelled', 'no_show');
CREATE TYPE lesson_type AS ENUM ('driving_lesson', 'mock_test_session', 'refresher_course', 'administrative_block');
CREATE TYPE booking_status AS ENUM ('confirmed', 'tentative', 'completed');
CREATE TYPE payment_method AS ENUM ('bank_transfer', 'cash', 'card', 'paypal', 'lesson_tracker_pro', 'cheque', 'online');
CREATE TYPE payment_type AS ENUM ('individual', 'block');
CREATE TYPE transaction_type AS ENUM ('income', 'expense');
CREATE TYPE expense_category AS ENUM (
  'accounts', 'advertising', 'association', 'bank_charges', 'computer',
  'dvsa_fees', 'equipment', 'food_drink', 'franchise_fee', 'fuel',
  'insurance_business', 'insurance_personal', 'insurance_vehicle',
  'insurance', 'maintenance', 'lease', 'training', 'other'
);
CREATE TYPE recurrence_type AS ENUM ('daily', 'working_days', 'weekly', 'fortnightly');
CREATE TYPE slot_group_filter AS ENUM ('current_pupils_only', 'private_to_school');
CREATE TYPE enquiry_status AS ENUM ('pending', 'contacted', 'interested', 'not_interested', 'converted');
CREATE TYPE experience_level AS ENUM ('beginner', 'intermediate', 'advanced');
CREATE TYPE test_result AS ENUM ('pending', 'pass', 'fail');
CREATE TYPE message_status AS ENUM ('sending', 'sent', 'delivered', 'seen');
CREATE TYPE subscription_status AS ENUM ('active', 'cancelled', 'expired', 'trial');
CREATE TYPE payment_request_status AS ENUM ('pending', 'approved', 'rejected', 'paid');
CREATE TYPE invitation_status AS ENUM ('pending', 'approved', 'accepted', 'declined');
CREATE TYPE resource_visibility AS ENUM ('public', 'private', 'selective');

-- =============================================================
-- PART 2: TABLES
-- =============================================================

-- ---------------------------------------------------------
-- 2.1 PROFILES (extends Supabase auth.users)
-- ---------------------------------------------------------
CREATE TABLE profiles (
  id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name       TEXT NOT NULL DEFAULT '',
  email           TEXT NOT NULL DEFAULT '',
  phone           TEXT NOT NULL DEFAULT '',
  avatar_url      TEXT,
  business_name   TEXT DEFAULT '',
  role            TEXT NOT NULL DEFAULT 'instructor' CHECK (role IN ('instructor', 'pupil', 'admin')),
  email_verified  BOOLEAN DEFAULT false,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------
-- 2.2 INSTRUCTOR SUBSCRIPTION PLANS
-- ---------------------------------------------------------
CREATE TABLE subscription_plans (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL,
  price           DECIMAL(10,2) NOT NULL DEFAULT 0,
  duration_months INT NOT NULL DEFAULT 1,
  features        JSONB DEFAULT '[]',
  is_free_tier    BOOLEAN DEFAULT false,
  is_active       BOOLEAN DEFAULT true,
  sort_order      INT DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------
-- 2.3 INSTRUCTOR SUBSCRIPTIONS
-- ---------------------------------------------------------
CREATE TABLE instructor_subscriptions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  plan_id         UUID REFERENCES subscription_plans(id) ON DELETE SET NULL,
  plan_type       TEXT NOT NULL DEFAULT '',
  amount          DECIMAL(10,2) NOT NULL DEFAULT 0,
  start_date      TIMESTAMPTZ NOT NULL DEFAULT now(),
  end_date        TIMESTAMPTZ NOT NULL,
  status          subscription_status NOT NULL DEFAULT 'active',
  payment_status  TEXT NOT NULL DEFAULT 'pending',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------
-- 2.4 PUPILS
-- ---------------------------------------------------------
CREATE TABLE pupils (
  id                              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id                   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  first_name                      TEXT NOT NULL DEFAULT '',
  last_name                       TEXT NOT NULL DEFAULT '',
  phone                           TEXT NOT NULL DEFAULT '',
  secondary_phone                 TEXT,
  email                           TEXT NOT NULL DEFAULT '',
  postcode                        TEXT,
  pickup_addresses                JSONB DEFAULT '[]',
  dropoff_addresses               JSONB DEFAULT '[]',
  assigned_postcode               TEXT,
  assigned_billing_rate_id        TEXT,
  hourly_rate                     DECIMAL(10,2) NOT NULL DEFAULT 40,
  mechanical_gearbox_preference   gearbox_type NOT NULL DEFAULT 'manual',
  status                          pupil_status NOT NULL DEFAULT 'current',
  tags                            JSONB DEFAULT '[]',
  availability                    JSONB DEFAULT '{}',
  weekly_availability_days        JSONB DEFAULT '[]',
  notes                           TEXT,
  on_waiting_list                 BOOLEAN DEFAULT false,
  invite_to_app                   BOOLEAN DEFAULT false,
  terms_accepted                  BOOLEAN DEFAULT false,
  require_signature_before_booking BOOLEAN DEFAULT false,
  aggregated_total_lessons_count  INT DEFAULT 0,
  gross_revenue_earned            DECIMAL(10,2) DEFAULT 0,
  package_time_prepaid_minutes    INT DEFAULT 0,
  package_time_remaining_minutes  INT DEFAULT 0,
  companion_app_linked_status     BOOLEAN DEFAULT false,
  outstanding_balance             DECIMAL(10,2) DEFAULT 0,
  progress_scores                 JSONB DEFAULT '{}',
  progress_scale_type             INT DEFAULT 5,
  test_date                       DATE,
  test_passed                     BOOLEAN,
  created_at                      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at                      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------
-- 2.5 INSTRUCTOR-PUPIL LINKS
-- ---------------------------------------------------------
CREATE TABLE instructor_pupil_links (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  pupil_id        UUID NOT NULL REFERENCES pupils(id) ON DELETE CASCADE,
  status          TEXT NOT NULL DEFAULT 'active',
  linked_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(instructor_id, pupil_id)
);

-- ---------------------------------------------------------
-- 2.6 PUPIL INVITATIONS
-- ---------------------------------------------------------
CREATE TABLE pupil_invitations (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  email           TEXT NOT NULL,
  first_name      TEXT DEFAULT '',
  last_name       TEXT DEFAULT '',
  phone           TEXT DEFAULT '',
  postcode        TEXT,
  status          invitation_status NOT NULL DEFAULT 'pending',
  accepted_at     TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------
-- 2.7 LESSONS
-- ---------------------------------------------------------
CREATE TABLE lessons (
  id                              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id                   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  pupil_id                        UUID NOT NULL REFERENCES pupils(id) ON DELETE CASCADE,
  pupil_name                      TEXT NOT NULL DEFAULT '',
  date                            DATE NOT NULL,
  time                            TIME NOT NULL,
  duration                        INT NOT NULL DEFAULT 60,
  type                            lesson_type NOT NULL DEFAULT 'driving_lesson',
  status                          lesson_status NOT NULL DEFAULT 'scheduled',
  rate                            DECIMAL(10,2) NOT NULL DEFAULT 0,
  paid                            BOOLEAN DEFAULT false,
  pickup_location                 TEXT,
  dropoff_location                TEXT,
  notes                           TEXT,
  is_recurring                    BOOLEAN DEFAULT false,
  shared_with_pupil               BOOLEAN DEFAULT false,
  require_online_payment          BOOLEAN DEFAULT false,
  session_classification          lesson_type DEFAULT 'driving_lesson',
  booking_status                  booking_status NOT NULL DEFAULT 'confirmed',
  is_shared_with_pupil_companion_view BOOLEAN DEFAULT false,
  created_at                      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at                      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------
-- 2.8 OPEN SLOTS
-- ---------------------------------------------------------
CREATE TABLE open_slots (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  date                DATE NOT NULL,
  start_time          TIME NOT NULL,
  duration            INT NOT NULL DEFAULT 60,
  is_recurring        BOOLEAN DEFAULT false,
  recurrence_type     recurrence_type,
  accepts_online_payment  BOOLEAN DEFAULT false,
  group_filter        slot_group_filter NOT NULL DEFAULT 'current_pupils_only',
  gearbox_filter      gearbox_type NOT NULL DEFAULT 'any',
  target_pupil_ids    JSONB DEFAULT '[]',
  custom_message      TEXT,
  slot_count          INT NOT NULL DEFAULT 1,
  status              booking_status NOT NULL DEFAULT 'tentative',
  is_booked           BOOLEAN DEFAULT false,
  offered_to_pupil_id UUID REFERENCES pupils(id) ON DELETE SET NULL,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------
-- 2.9 CALENDAR EVENTS
-- ---------------------------------------------------------
CREATE TABLE calendar_events (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id           UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title                   TEXT NOT NULL,
  location                TEXT,
  date                    DATE NOT NULL,
  time                    TIME,
  is_all_day              BOOLEAN DEFAULT false,
  notes                   TEXT,
  end_date                DATE,
  end_time                TIME,
  sync_to_external_calendar BOOLEAN DEFAULT false,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------
-- 2.10 TRANSACTIONS (Income & Expenses)
-- ---------------------------------------------------------
CREATE TABLE transactions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  pupil_id        UUID REFERENCES pupils(id) ON DELETE SET NULL,
  pupil_name      TEXT,
  type            transaction_type NOT NULL,
  amount          DECIMAL(10,2) NOT NULL,
  description     TEXT NOT NULL DEFAULT '',
  date            DATE NOT NULL DEFAULT CURRENT_DATE,
  payment_method  payment_method,
  payment_type    payment_type,
  category        expense_category,
  is_recurring    BOOLEAN DEFAULT false,
  receipt_url     TEXT,
  vendor_name     TEXT,
  is_reconciled   BOOLEAN DEFAULT false,
  tax_deductible  BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------
-- 2.11 INVOICES (Payment Requests from Instructor to Pupil)
-- ---------------------------------------------------------
CREATE TABLE invoices (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id           UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  pupil_id                UUID NOT NULL REFERENCES pupils(id) ON DELETE CASCADE,
  pupil_name              TEXT NOT NULL DEFAULT '',
  amount                  DECIMAL(10,2) NOT NULL,
  status                  TEXT NOT NULL DEFAULT 'pending',
  issued_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
  due_date                DATE NOT NULL,
  stripe_payment_intent_id TEXT,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------
-- 2.12 MESSAGES (Instructor-Pupil Chat)
-- ---------------------------------------------------------
CREATE TABLE messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  receiver_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  pupil_id        UUID REFERENCES pupils(id) ON DELETE SET NULL,
  pupil_name      TEXT NOT NULL DEFAULT '',
  body            TEXT NOT NULL,
  is_from_instructor BOOLEAN NOT NULL DEFAULT true,
  is_locked       BOOLEAN DEFAULT false,
  status          message_status NOT NULL DEFAULT 'sent',
  is_edited       BOOLEAN DEFAULT false,
  is_deleted      BOOLEAN DEFAULT false,
  scheduled_for   TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------
-- 2.13 NOTIFICATIONS
-- ---------------------------------------------------------
CREATE TABLE app_notifications (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title           TEXT NOT NULL,
  body            TEXT NOT NULL DEFAULT '',
  is_read         BOOLEAN DEFAULT false,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------
-- 2.14 ENQUIRIES
-- ---------------------------------------------------------
CREATE TABLE enquiries (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id           UUID REFERENCES profiles(id) ON DELETE CASCADE,
  first_name              TEXT NOT NULL DEFAULT '',
  last_name               TEXT NOT NULL DEFAULT '',
  email                   TEXT NOT NULL DEFAULT '',
  phone                   TEXT NOT NULL DEFAULT '',
  address                 TEXT DEFAULT '',
  postcode                TEXT DEFAULT '',
  notes                   TEXT DEFAULT '',
  experience              experience_level NOT NULL DEFAULT 'beginner',
  gearbox_preference      gearbox_type NOT NULL DEFAULT 'manual',
  has_provisional_license BOOLEAN DEFAULT false,
  prior_practice_hours    INT DEFAULT 0,
  weekly_availability_days JSONB DEFAULT '[]',
  availability            JSONB DEFAULT '[]',
  status                  enquiry_status NOT NULL DEFAULT 'pending',
  last_contacted          TIMESTAMPTZ,
  source                  TEXT,
  assigned_to_id          UUID REFERENCES profiles(id) ON DELETE SET NULL,
  is_mock_data            BOOLEAN DEFAULT false,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------
-- 2.15 TEST REPORTS
-- ---------------------------------------------------------
CREATE TABLE test_reports (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  pupil_id          UUID NOT NULL REFERENCES pupils(id) ON DELETE CASCADE,
  pupil_name        TEXT NOT NULL DEFAULT '',
  test_date         DATE NOT NULL,
  grade_level       TEXT DEFAULT 'Practical',
  result            test_result NOT NULL DEFAULT 'pending',
  manoeuvres        JSONB DEFAULT '[]',
  scales_notes      TEXT DEFAULT '',
  aural_notes       TEXT DEFAULT '',
  notes             TEXT DEFAULT '',
  test_center_id    INT DEFAULT 0,
  test_center_name  TEXT,
  faults            INT DEFAULT 0,
  serious_faults    INT DEFAULT 0,
  dangerous_faults  INT DEFAULT 0,
  examiner_name     TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------
-- 2.16 MILEAGE ENTRIES
-- ---------------------------------------------------------
CREATE TABLE mileage_entries (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  miles           DECIMAL(8,1) NOT NULL,
  date            DATE NOT NULL DEFAULT CURRENT_DATE,
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------
-- 2.17 VEHICLES
-- ---------------------------------------------------------
CREATE TABLE vehicles (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  make                TEXT NOT NULL DEFAULT '',
  model               TEXT NOT NULL DEFAULT '',
  registration_plate  TEXT NOT NULL DEFAULT '',
  gearbox             gearbox_type NOT NULL DEFAULT 'manual',
  mot_expiry_date     DATE NOT NULL,
  tax_expiry_date     DATE NOT NULL,
  insurance_expiry_date DATE NOT NULL,
  last_service_date   DATE,
  current_mileage     INT DEFAULT 0,
  is_primary          BOOLEAN DEFAULT false,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------
-- 2.18 PROGRESS CATEGORIES
-- ---------------------------------------------------------
CREATE TABLE progress_categories (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title           TEXT NOT NULL,
  description     TEXT DEFAULT '',
  order_index     INT DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------
-- 2.19 PROGRESS SKILLS
-- ---------------------------------------------------------
CREATE TABLE progress_skills (
  id                            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id                   UUID NOT NULL REFERENCES progress_categories(id) ON DELETE CASCADE,
  pupil_id                      UUID NOT NULL REFERENCES pupils(id) ON DELETE CASCADE,
  title                         TEXT NOT NULL,
  description                   TEXT DEFAULT '',
  skill_level                   INT DEFAULT 0,
  order_index                   INT DEFAULT 0,
  requires_independent_driving  BOOLEAN DEFAULT false,
  created_at                    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at                    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------
-- 2.20 TEACHING RESOURCES
-- ---------------------------------------------------------
CREATE TABLE teaching_resources (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title               TEXT NOT NULL,
  description         TEXT DEFAULT '',
  file_url            TEXT,
  file_type           TEXT DEFAULT 'link',
  visibility          resource_visibility NOT NULL DEFAULT 'public',
  selected_pupil_ids  JSONB DEFAULT '[]',
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------
-- 2.21 ACTIVITY LOGS
-- ---------------------------------------------------------
CREATE TABLE instructor_activity_logs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  action          TEXT NOT NULL,
  details         TEXT DEFAULT '',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------
-- 2.22 PROMO CODES (Admin)
-- ---------------------------------------------------------
CREATE TABLE promo_codes (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code            TEXT NOT NULL UNIQUE,
  description     TEXT DEFAULT '',
  discount_type   TEXT NOT NULL DEFAULT 'percentage' CHECK (discount_type IN ('percentage', 'fixed')),
  discount_value  DECIMAL(10,2) NOT NULL,
  max_uses        INT DEFAULT 0,
  current_uses    INT DEFAULT 0,
  expires_at      TIMESTAMPTZ,
  is_active       BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------
-- 2.23 BANNERS (Public)
-- ---------------------------------------------------------
CREATE TABLE banners (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title           TEXT NOT NULL DEFAULT '',
  image_url       TEXT,
  link_url        TEXT,
  is_active       BOOLEAN DEFAULT true,
  sort_order      INT DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------
-- 2.24 APP SETTINGS (Key-Value Store)
-- ---------------------------------------------------------
CREATE TABLE app_settings (
  key             TEXT PRIMARY KEY,
  value           JSONB NOT NULL DEFAULT '{}',
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------
-- 2.25 INSTRUCTOR LOCATIONS (GPS Tracking)
-- ---------------------------------------------------------
CREATE TABLE instructor_locations (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  latitude        DECIMAL(10,7) NOT NULL,
  longitude       DECIMAL(10,7) NOT NULL,
  accuracy        DECIMAL(5,1),
  timestamp       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------
-- 2.26 PAYMENT REQUESTS (Instructor → Admin)
-- ---------------------------------------------------------
CREATE TABLE instructor_payment_requests (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  amount          DECIMAL(10,2) NOT NULL,
  description     TEXT DEFAULT '',
  status          payment_request_status NOT NULL DEFAULT 'pending',
  reviewed_by     UUID REFERENCES profiles(id) ON DELETE SET NULL,
  reviewed_at     TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================
-- PART 3: INDEXES
-- =============================================================

-- Profiles
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_email ON profiles(email);

-- Pupils
CREATE INDEX idx_pupils_instructor ON pupils(instructor_id);
CREATE INDEX idx_pupils_status ON pupils(status);
CREATE INDEX idx_pupils_email ON pupils(email);
CREATE INDEX idx_pupils_phone ON pupils(phone);

-- Instructor-Pupil Links
CREATE INDEX idx_ipl_instructor ON instructor_pupil_links(instructor_id);
CREATE INDEX idx_ipl_pupil ON instructor_pupil_links(pupil_id);

-- Pupil Invitations
CREATE INDEX idx_pupil_invitations_instructor ON pupil_invitations(instructor_id);
CREATE INDEX idx_pupil_invitations_email ON pupil_invitations(email);
CREATE INDEX idx_pupil_invitations_status ON pupil_invitations(status);

-- Lessons
CREATE INDEX idx_lessons_instructor ON lessons(instructor_id);
CREATE INDEX idx_lessons_pupil ON lessons(pupil_id);
CREATE INDEX idx_lessons_date ON lessons(date);
CREATE INDEX idx_lessons_instructor_date ON lessons(instructor_id, date);
CREATE INDEX idx_lessons_status ON lessons(status);

-- Open Slots
CREATE INDEX idx_open_slots_instructor ON open_slots(instructor_id);
CREATE INDEX idx_open_slots_date ON open_slots(date);
CREATE INDEX idx_open_slots_available ON open_slots(instructor_id, date) WHERE is_booked = false;

-- Calendar Events
CREATE INDEX idx_calendar_events_instructor ON calendar_events(instructor_id);
CREATE INDEX idx_calendar_events_date ON calendar_events(date);

-- Transactions
CREATE INDEX idx_transactions_instructor ON transactions(instructor_id);
CREATE INDEX idx_transactions_pupil ON transactions(pupil_id);
CREATE INDEX idx_transactions_date ON transactions(date);
CREATE INDEX idx_transactions_type ON transactions(instructor_id, type);

-- Invoices
CREATE INDEX idx_invoices_instructor ON invoices(instructor_id);
CREATE INDEX idx_invoices_pupil ON invoices(pupil_id);
CREATE INDEX idx_invoices_status ON invoices(status);

-- Messages
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_receiver ON messages(receiver_id);
CREATE INDEX idx_messages_pupil ON messages(pupil_id);
CREATE INDEX idx_messages_created ON messages(created_at);
CREATE INDEX idx_messages_conversation ON messages(sender_id, receiver_id);

-- Notifications
CREATE INDEX idx_notifications_user ON app_notifications(user_id);
CREATE INDEX idx_notifications_read ON app_notifications(user_id, is_read);

-- Enquiries
CREATE INDEX idx_enquiries_instructor ON enquiries(instructor_id);
CREATE INDEX idx_enquiries_status ON enquiries(status);

-- Test Reports
CREATE INDEX idx_test_reports_instructor ON test_reports(instructor_id);
CREATE INDEX idx_test_reports_pupil ON test_reports(pupil_id);

-- Mileage
CREATE INDEX idx_mileage_instructor ON mileage_entries(instructor_id);
CREATE INDEX idx_mileage_date ON mileage_entries(date);

-- Vehicles
CREATE INDEX idx_vehicles_instructor ON vehicles(instructor_id);

-- Progress
CREATE INDEX idx_progress_categories_instructor ON progress_categories(instructor_id);
CREATE INDEX idx_progress_skills_pupil ON progress_skills(pupil_id);
CREATE INDEX idx_progress_skills_category ON progress_skills(category_id);

-- Teaching Resources
CREATE INDEX idx_teaching_resources_instructor ON teaching_resources(instructor_id);

-- Activity Logs
CREATE INDEX idx_activity_logs_instructor ON instructor_activity_logs(instructor_id);
CREATE INDEX idx_activity_logs_created ON instructor_activity_logs(created_at);

-- Instructor Subscriptions
CREATE INDEX idx_subscriptions_instructor ON instructor_subscriptions(instructor_id);
CREATE INDEX idx_subscriptions_status ON instructor_subscriptions(status);
CREATE INDEX idx_subscriptions_active ON instructor_subscriptions(instructor_id) WHERE status = 'active';

-- Promo Codes
CREATE INDEX idx_promo_codes_code ON promo_codes(code);
CREATE INDEX idx_promo_codes_active ON promo_codes(is_active);

-- Locations
CREATE INDEX idx_locations_instructor ON instructor_locations(instructor_id);
CREATE INDEX idx_locations_timestamp ON instructor_locations(timestamp);

-- Payment Requests
CREATE INDEX idx_payment_requests_instructor ON instructor_payment_requests(instructor_id);
CREATE INDEX idx_payment_requests_status ON instructor_payment_requests(status);

-- =============================================================
-- PART 4: TRIGGERS (Auto-update updated_at)
-- =============================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to all tables with updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_pupils_updated_at BEFORE UPDATE ON pupils FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_lessons_updated_at BEFORE UPDATE ON lessons FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_open_slots_updated_at BEFORE UPDATE ON open_slots FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_calendar_events_updated_at BEFORE UPDATE ON calendar_events FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_messages_updated_at BEFORE UPDATE ON messages FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_enquiries_updated_at BEFORE UPDATE ON enquiries FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_test_reports_updated_at BEFORE UPDATE ON test_reports FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_vehicles_updated_at BEFORE UPDATE ON vehicles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_progress_categories_updated_at BEFORE UPDATE ON progress_categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_progress_skills_updated_at BEFORE UPDATE ON progress_skills FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_teaching_resources_updated_at BEFORE UPDATE ON teaching_resources FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_subscription_plans_updated_at BEFORE UPDATE ON subscription_plans FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_instructor_subscriptions_updated_at BEFORE UPDATE ON instructor_subscriptions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_pupil_invitations_updated_at BEFORE UPDATE ON pupil_invitations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_promo_codes_updated_at BEFORE UPDATE ON promo_codes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_banners_updated_at BEFORE UPDATE ON banners FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_instructor_payment_requests_updated_at BEFORE UPDATE ON instructor_payment_requests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================
-- PART 5: ROW LEVEL SECURITY (RLS)
-- =============================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE pupils ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructor_pupil_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE pupil_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE open_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;
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
ALTER TABLE instructor_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE promo_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructor_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructor_payment_requests ENABLE ROW LEVEL SECURITY;

-- Security definer function to check admin role without RLS recursion
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql SECURITY DEFINER STABLE
AS $$
  SELECT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
$$;

-- ---------------------------------------------------------
-- 5.1 PROFILES: Users can read own profile; admins read all
-- ---------------------------------------------------------
CREATE POLICY "users_read_own_profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "users_update_own_profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "admins_read_all_profiles" ON profiles
  FOR SELECT USING (public.is_admin());

CREATE POLICY "insert_own_profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- ---------------------------------------------------------
-- 5.2 PUPILS: Instructors CRUD own pupils; pupils read own
-- ---------------------------------------------------------
CREATE POLICY "instructors_manage_pupils" ON pupils
  FOR ALL USING (instructor_id = auth.uid());

CREATE POLICY "pupils_read_own" ON pupils
  FOR SELECT USING (id = auth.uid());

CREATE POLICY "admins_read_all_pupils" ON pupils
  FOR SELECT USING (
    public.is_admin()
  );

-- ---------------------------------------------------------
-- 5.3 INSTRUCTOR-PUPIL LINKS
-- ---------------------------------------------------------
CREATE POLICY "instructors_manage_links" ON instructor_pupil_links
  FOR ALL USING (instructor_id = auth.uid());

CREATE POLICY "pupils_read_own_links" ON instructor_pupil_links
  FOR SELECT USING (pupil_id = auth.uid());

-- ---------------------------------------------------------
-- 5.4 PUPIL INVITATIONS
-- ---------------------------------------------------------
CREATE POLICY "instructors_manage_invitations" ON pupil_invitations
  FOR ALL USING (instructor_id = auth.uid());

CREATE POLICY "pupils_read_own_invitations" ON pupil_invitations
  FOR SELECT USING (email = (SELECT email FROM profiles WHERE id = auth.uid()));

-- ---------------------------------------------------------
-- 5.5 LESSONS
-- ---------------------------------------------------------
CREATE POLICY "instructors_manage_lessons" ON lessons
  FOR ALL USING (instructor_id = auth.uid());

CREATE POLICY "pupils_read_own_lessons" ON lessons
  FOR SELECT USING (pupil_id = auth.uid());

-- ---------------------------------------------------------
-- 5.6 OPEN SLOTS
-- ---------------------------------------------------------
CREATE POLICY "instructors_manage_slots" ON open_slots
  FOR ALL USING (instructor_id = auth.uid());

CREATE POLICY "pupils_read_available_slots" ON open_slots
  FOR SELECT USING (is_booked = false AND status = 'confirmed');

-- ---------------------------------------------------------
-- 5.7 CALENDAR EVENTS
-- ---------------------------------------------------------
CREATE POLICY "instructors_manage_events" ON calendar_events
  FOR ALL USING (instructor_id = auth.uid());

-- ---------------------------------------------------------
-- 5.8 TRANSACTIONS
-- ---------------------------------------------------------
CREATE POLICY "instructors_manage_transactions" ON transactions
  FOR ALL USING (instructor_id = auth.uid());

CREATE POLICY "pupils_read_own_transactions" ON transactions
  FOR SELECT USING (pupil_id = auth.uid());

-- ---------------------------------------------------------
-- 5.9 INVOICES
-- ---------------------------------------------------------
CREATE POLICY "instructors_manage_invoices" ON invoices
  FOR ALL USING (instructor_id = auth.uid());

CREATE POLICY "pupils_read_own_invoices" ON invoices
  FOR SELECT USING (pupil_id = auth.uid());

-- ---------------------------------------------------------
-- 5.10 MESSAGES
-- ---------------------------------------------------------
CREATE POLICY "users_manage_own_messages" ON messages
  FOR ALL USING (auth.uid() IN (sender_id, receiver_id));

-- ---------------------------------------------------------
-- 5.11 NOTIFICATIONS
-- ---------------------------------------------------------
CREATE POLICY "users_manage_own_notifications" ON app_notifications
  FOR ALL USING (user_id = auth.uid());

-- ---------------------------------------------------------
-- 5.12 ENQUIRIES
-- ---------------------------------------------------------
CREATE POLICY "instructors_manage_enquiries" ON enquiries
  FOR ALL USING (instructor_id = auth.uid());

CREATE POLICY "pupils_read_own_enquiries" ON enquiries
  FOR SELECT USING (email = (SELECT email FROM profiles WHERE id = auth.uid()));

-- ---------------------------------------------------------
-- 5.13 TEST REPORTS
-- ---------------------------------------------------------
CREATE POLICY "instructors_manage_test_reports" ON test_reports
  FOR ALL USING (instructor_id = auth.uid());

CREATE POLICY "pupils_read_own_test_reports" ON test_reports
  FOR SELECT USING (pupil_id = auth.uid());

-- ---------------------------------------------------------
-- 5.14 MILEAGE
-- ---------------------------------------------------------
CREATE POLICY "instructors_manage_mileage" ON mileage_entries
  FOR ALL USING (instructor_id = auth.uid());

-- ---------------------------------------------------------
-- 5.15 VEHICLES
-- ---------------------------------------------------------
CREATE POLICY "instructors_manage_vehicles" ON vehicles
  FOR ALL USING (instructor_id = auth.uid());

-- ---------------------------------------------------------
-- 5.16 PROGRESS CATEGORIES
-- ---------------------------------------------------------
CREATE POLICY "instructors_manage_progress_categories" ON progress_categories
  FOR ALL USING (instructor_id = auth.uid());

-- ---------------------------------------------------------
-- 5.17 PROGRESS SKILLS
-- ---------------------------------------------------------
CREATE POLICY "instructors_manage_progress_skills" ON progress_skills
  FOR ALL USING (
    EXISTS (SELECT 1 FROM progress_categories WHERE id = category_id AND instructor_id = auth.uid())
  );

CREATE POLICY "pupils_read_own_progress" ON progress_skills
  FOR SELECT USING (pupil_id = auth.uid());

-- ---------------------------------------------------------
-- 5.18 TEACHING RESOURCES
-- ---------------------------------------------------------
CREATE POLICY "instructors_manage_resources" ON teaching_resources
  FOR ALL USING (instructor_id = auth.uid());

CREATE POLICY "pupils_read_public_resources" ON teaching_resources
  FOR SELECT USING (
    visibility = 'public'
    OR (visibility = 'selective' AND selected_pupil_ids ? (SELECT id::text FROM profiles WHERE id = auth.uid()))
  );

-- ---------------------------------------------------------
-- 5.19 ACTIVITY LOGS
-- ---------------------------------------------------------
CREATE POLICY "instructors_read_own_logs" ON instructor_activity_logs
  FOR SELECT USING (instructor_id = auth.uid());

CREATE POLICY "instructors_insert_logs" ON instructor_activity_logs
  FOR INSERT WITH CHECK (instructor_id = auth.uid());

-- ---------------------------------------------------------
-- 5.20 SUBSCRIPTIONS
-- ---------------------------------------------------------
CREATE POLICY "instructors_read_own_subscription" ON instructor_subscriptions
  FOR SELECT USING (instructor_id = auth.uid());

CREATE POLICY "instructors_insert_own_subscription" ON instructor_subscriptions
  FOR INSERT WITH CHECK (instructor_id = auth.uid());

CREATE POLICY "admins_manage_subscriptions" ON instructor_subscriptions
  FOR ALL USING (
    public.is_admin()
  );

-- ---------------------------------------------------------
-- 5.21 SUBSCRIPTION PLANS (public read, admin write)
-- ---------------------------------------------------------
CREATE POLICY "anyone_read_plans" ON subscription_plans
  FOR SELECT USING (true);

CREATE POLICY "admins_manage_plans" ON subscription_plans
  FOR ALL USING (
    public.is_admin()
  );

-- ---------------------------------------------------------
-- 5.22 PROMO CODES
-- ---------------------------------------------------------
CREATE POLICY "admins_manage_promo_codes" ON promo_codes
  FOR ALL USING (
    public.is_admin()
  );

-- ---------------------------------------------------------
-- 5.23 BANNERS (public read, admin write)
-- ---------------------------------------------------------
CREATE POLICY "anyone_read_banners" ON banners
  FOR SELECT USING (is_active = true);

CREATE POLICY "admins_manage_banners" ON banners
  FOR ALL USING (
    public.is_admin()
  );

-- ---------------------------------------------------------
-- 5.24 APP SETTINGS
-- ---------------------------------------------------------
CREATE POLICY "admins_manage_app_settings" ON app_settings
  FOR ALL USING (
    public.is_admin()
  );

-- ---------------------------------------------------------
-- 5.25 INSTRUCTOR LOCATIONS
-- ---------------------------------------------------------
CREATE POLICY "instructors_manage_own_locations" ON instructor_locations
  FOR ALL USING (instructor_id = auth.uid());

CREATE POLICY "admins_read_locations" ON instructor_locations
  FOR SELECT USING (
    public.is_admin()
  );

-- ---------------------------------------------------------
-- 5.26 PAYMENT REQUESTS
-- ---------------------------------------------------------
CREATE POLICY "instructors_manage_own_requests" ON instructor_payment_requests
  FOR ALL USING (instructor_id = auth.uid());

CREATE POLICY "admins_manage_payment_requests" ON instructor_payment_requests
  FOR ALL USING (
    public.is_admin()
  );

-- =============================================================
-- PART 6: SEED DATA
-- =============================================================

-- Default subscription plans
INSERT INTO subscription_plans (name, price, duration_months, features, is_free_tier, is_active, sort_order) VALUES
  ('Free Trial', 0, 2, '["Up to 5 pupils", "Basic diary", "Manual payment tracking"]', true, true, 0),
  ('Starter', 9.99, 1, '["Up to 10 pupils", "Smart diary", "Payment tracking", "Pupil messaging"]', false, true, 1),
  ('Professional', 19.99, 1, '["Unlimited pupils", "Smart diary with slots", "Full financial reports", "Pupil messaging & portal", "Progress tracking", "Test reports"]', false, true, 2),
  ('Premium', 29.99, 1, '["Everything in Professional", "Online booking", "Route planning", "Priority support", "Custom branding", "API access", "Multi-instructor support"]', false, true, 3);

-- Default app settings
INSERT INTO app_settings (key, value) VALUES
  ('platform_name', '"Lesson Tracker Pro"'),
  ('platform_fee_percentage', '2.9'),
  ('free_trial_days', '60'),
  ('default_currency', '"GBP"'),
  ('support_email', '"support@lessontrackerpro.com"');

-- =============================================================
-- PART 7: AUTH TRIGGER (Auto-create profile on signup)
-- =============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
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

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================================
-- SCHEMA COMPLETE
-- =============================================================