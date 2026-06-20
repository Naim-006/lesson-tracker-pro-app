-- =============================================================
-- LESSON TRACKER PRO - DEFINITIVE SCHEMA (v3.0)
-- Single source of truth. Matches ALL app code exactly.
-- Run ONCE in Supabase SQL Editor on a clean database.
-- =============================================================

-- =============================================================
-- PART 0: GRANTS (must be first)
-- =============================================================
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon, authenticated, service_role;

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
CREATE TYPE expense_category AS ENUM ('accounts', 'advertising', 'association', 'bank_charges', 'computer', 'dvsa_fees', 'equipment', 'food_drink', 'franchise_fee', 'fuel', 'insurance_business', 'insurance_personal', 'insurance_vehicle', 'insurance', 'maintenance', 'lease', 'training', 'other');
CREATE TYPE recurrence_type AS ENUM ('daily', 'working_days', 'weekly', 'fortnightly');
CREATE TYPE slot_group_filter AS ENUM ('current_pupils_only', 'private_to_school');
CREATE TYPE enquiry_status AS ENUM ('pending', 'contacted', 'interested', 'not_interested', 'converted');
CREATE TYPE experience_level AS ENUM ('beginner', 'intermediate', 'advanced');
CREATE TYPE test_result AS ENUM ('pending', 'pass', 'fail');
CREATE TYPE message_status AS ENUM ('sending', 'sent', 'delivered', 'seen');
CREATE TYPE subscription_status AS ENUM ('active', 'cancelled', 'expired', 'trial');
CREATE TYPE invitation_status AS ENUM ('pending', 'approved', 'accepted', 'declined');
CREATE TYPE resource_visibility AS ENUM ('public', 'private', 'selective');

-- =============================================================
-- PART 2: TABLES
-- =============================================================

-- 2.1 PROFILES (extends auth.users)
-- id is NOT FK to auth.users because instructors create pupil profiles
-- before the pupil has an auth account. The auth trigger handles
-- creating a profile row when a user signs up.
CREATE TABLE profiles (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name         TEXT NOT NULL DEFAULT '',
  email             TEXT NOT NULL DEFAULT '',
  phone             TEXT NOT NULL DEFAULT '',
  avatar_url        TEXT,
  business_name     TEXT DEFAULT '',
  role              TEXT NOT NULL DEFAULT 'instructor' CHECK (role IN ('instructor', 'pupil', 'admin')),
  email_verified    BOOLEAN DEFAULT false,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.2 SUBSCRIPTION PLANS
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

-- 2.3 INSTRUCTOR SUBSCRIPTIONS
CREATE TABLE instructor_subscriptions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  plan_id         UUID REFERENCES subscription_plans(id) ON DELETE SET NULL,
  plan_type       TEXT DEFAULT '',
  amount          DECIMAL(10,2) DEFAULT 0,
  start_date      TIMESTAMPTZ NOT NULL DEFAULT now(),
  end_date        TIMESTAMPTZ,
  status          TEXT NOT NULL DEFAULT 'trial',
  payment_status  TEXT DEFAULT 'pending',
  trial_end_date  TIMESTAMPTZ,
  cancelled_at    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.4 PUPILS
-- id is a generated UUID. When a pupil signs up via auth, a profile
-- with the same id is created by the auth trigger.
CREATE TABLE pupils (
  id                                UUID PRIMARY KEY DEFAULT gen_random_uuid() REFERENCES profiles(id) ON DELETE CASCADE,
  instructor_id                     UUID REFERENCES profiles(id) ON DELETE CASCADE,
  first_name                        TEXT NOT NULL DEFAULT '',
  last_name                         TEXT NOT NULL DEFAULT '',
  phone                             TEXT NOT NULL DEFAULT '',
  secondary_phone                   TEXT,
  email                             TEXT NOT NULL DEFAULT '',
  postcode                          TEXT,
  address                           TEXT,
  pickup_addresses                  JSONB DEFAULT '[]',
  dropoff_address                   TEXT,
  dropoff_addresses                 JSONB DEFAULT '[]',
  assigned_postcode                 TEXT,
  assigned_billing_rate_id          TEXT,
  hourly_rate                       DECIMAL(10,2) NOT NULL DEFAULT 40,
  mechanical_gearbox_preference     TEXT NOT NULL DEFAULT 'manual',
  gearbox_preference                TEXT DEFAULT 'any',
  status                            TEXT NOT NULL DEFAULT 'current',
  tags                              JSONB DEFAULT '[]',
  availability                      JSONB DEFAULT '{}',
  weekly_availability               JSONB DEFAULT '[]',
  weekly_availability_days          JSONB DEFAULT '[]',
  notes                             TEXT,
  on_waiting_list                   BOOLEAN DEFAULT false,
  invite_to_app                     BOOLEAN DEFAULT false,
  terms_accepted                    BOOLEAN DEFAULT false,
  require_signature_before_booking  BOOLEAN DEFAULT false,
  aggregated_total_lessons_count    INT DEFAULT 0,
  gross_revenue_earned              DECIMAL(10,2) DEFAULT 0,
  package_time_prepaid_minutes      INT DEFAULT 0,
  package_time_remaining_minutes    INT DEFAULT 0,
  companion_app_linked_status       BOOLEAN DEFAULT false,
  outstanding_balance               DECIMAL(10,2) DEFAULT 0,
  progress_scores                   JSONB DEFAULT '{}',
  progress_scale_type               INT DEFAULT 5,
  test_date                         DATE,
  test_passed                       BOOLEAN,
  test_progress                     TEXT,
  registration_timestamp            BIGINT DEFAULT 0,
  created_at                        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at                        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.5 INSTRUCTOR-PUPIL LINKS
CREATE TABLE instructor_pupil_links (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  pupil_id        UUID NOT NULL REFERENCES pupils(id) ON DELETE CASCADE,
  status          TEXT NOT NULL DEFAULT 'active',
  linked_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(instructor_id, pupil_id)
);

-- 2.6 PUPIL INVITATIONS (manual email invites)
CREATE TABLE pupil_invitations (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  email           TEXT NOT NULL,
  first_name      TEXT DEFAULT '',
  last_name       TEXT DEFAULT '',
  phone           TEXT DEFAULT '',
  postcode        TEXT,
  invitation_code TEXT,
  status          TEXT NOT NULL DEFAULT 'pending',
  source          TEXT DEFAULT 'manual',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  accepted_at     TIMESTAMPTZ
);

-- 2.7 PUPIL INVITE LINKS (shareable web link)
CREATE TABLE pupil_invite_links (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  token           TEXT UNIQUE NOT NULL,
  expires_at      TIMESTAMPTZ,
  is_active       BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.8 PUPIL INVITE SUBMISSIONS (submitted via web form)
CREATE TABLE pupil_invite_submissions (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  link_id                 UUID REFERENCES pupil_invite_links(id) ON DELETE CASCADE,
  instructor_id           UUID REFERENCES profiles(id) ON DELETE CASCADE,
  pupil_token             TEXT UNIQUE,
  first_name              TEXT NOT NULL DEFAULT '',
  last_name               TEXT NOT NULL DEFAULT '',
  email                   TEXT NOT NULL DEFAULT '',
  phone                   TEXT DEFAULT '',
  address                 TEXT DEFAULT '',
  postcode                TEXT DEFAULT '',
  pickup_location         TEXT DEFAULT '',
  dropoff_location        TEXT DEFAULT '',
  preferred_days          JSONB DEFAULT '[]',
  preferred_times         JSONB DEFAULT '[]',
  learning_goals          TEXT DEFAULT '',
  experience_level        TEXT DEFAULT '',
  emergency_contact_name  TEXT DEFAULT '',
  emergency_contact_phone TEXT DEFAULT '',
  notes                   TEXT DEFAULT '',
  status                  TEXT DEFAULT 'pending',
  reviewed_at             TIMESTAMPTZ,
  review_notes            TEXT,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.9 LESSONS
CREATE TABLE lessons (
  id                                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id                     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  pupil_id                          UUID NOT NULL REFERENCES pupils(id) ON DELETE CASCADE,
  pupil_name                        TEXT NOT NULL DEFAULT '',
  title                             TEXT,
  date                              DATE NOT NULL,
  time                              TEXT,
  start_time                        TEXT,
  end_time                          TEXT,
  duration                          INT NOT NULL DEFAULT 60,
  duration_min                      INT DEFAULT 60,
  type                              TEXT NOT NULL DEFAULT 'driving_lesson',
  lesson_type                       TEXT DEFAULT 'driving_lesson',
  status                            TEXT NOT NULL DEFAULT 'scheduled',
  rate                              DECIMAL(10,2) DEFAULT 0,
  price                             DECIMAL(10,2) DEFAULT 0,
  paid                              BOOLEAN DEFAULT false,
  pickup_location                   TEXT,
  dropoff_location                  TEXT,
  pickup_address                    TEXT,
  dropoff_address                   TEXT,
  notes                             TEXT,
  is_recurring                      BOOLEAN DEFAULT false,
  shared_with_pupil                 BOOLEAN DEFAULT false,
  require_online_payment            BOOLEAN DEFAULT false,
  session_classification            TEXT DEFAULT 'driving_lesson',
  booking_status                    TEXT DEFAULT 'confirmed',
  is_shared_with_pupil_companion_view BOOLEAN DEFAULT false,
  created_at                        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at                        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.10 OPEN SLOTS
CREATE TABLE open_slots (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  date                DATE,
  start_time          TEXT,
  end_time            TEXT,
  duration            INT DEFAULT 60,
  is_recurring        BOOLEAN DEFAULT false,
  recurrence_type     TEXT,
  recurrence          TEXT,
  accepts_online_payment BOOLEAN DEFAULT false,
  group_filter        TEXT DEFAULT 'currentPupilsOnly',
  gearbox_filter      TEXT DEFAULT 'any',
  target_pupil_ids    JSONB DEFAULT '[]',
  custom_message      TEXT,
  slot_count          INT DEFAULT 1,
  status              TEXT DEFAULT 'available',
  is_booked           BOOLEAN DEFAULT false,
  offered_to_pupil_id TEXT,
  booked_by           UUID REFERENCES pupils(id) ON DELETE SET NULL,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.11 CALENDAR EVENTS (instructor diary)
CREATE TABLE calendar_events (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id           UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  pupil_id                UUID REFERENCES pupils(id) ON DELETE SET NULL,
  title                   TEXT NOT NULL,
  description             TEXT,
  location                TEXT,
  date                    DATE NOT NULL,
  time                    TEXT,
  start_time              TEXT,
  end_time                TEXT,
  event_date              TEXT,
  event_time              TEXT,
  start_date              TEXT,
  end_date                TEXT,
  end_time                TEXT,
  is_all_day              BOOLEAN DEFAULT false,
  notes                   TEXT,
  color                   TEXT,
  event_type              TEXT DEFAULT 'lesson',
  is_completed            BOOLEAN DEFAULT false,
  completed               BOOLEAN DEFAULT false,
  sync_to_external_calendar BOOLEAN DEFAULT false,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.12 EVENTS (admin announcements)
CREATE TABLE events (
  id              SERIAL PRIMARY KEY,
  title           TEXT NOT NULL,
  description     TEXT,
  event_date      TEXT,
  is_published    BOOLEAN DEFAULT false,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.13 TRANSACTIONS (generic income/expense)
CREATE TABLE transactions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  pupil_id        UUID REFERENCES pupils(id) ON DELETE SET NULL,
  pupil_name      TEXT,
  type            TEXT NOT NULL DEFAULT 'income',
  amount          DECIMAL(10,2) NOT NULL,
  description     TEXT DEFAULT '',
  date            DATE NOT NULL DEFAULT CURRENT_DATE,
  category        TEXT,
  payment_method  TEXT,
  payment_type    TEXT,
  is_recurring    BOOLEAN DEFAULT false,
  receipt_url     TEXT,
  vendor_name     TEXT,
  is_reconciled   BOOLEAN DEFAULT false,
  tax_deductible  BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.14 INVOICES (payment requests from instructor to pupil)
CREATE TABLE invoices (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id           UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  pupil_id                UUID NOT NULL REFERENCES pupils(id) ON DELETE CASCADE,
  pupil_name              TEXT DEFAULT '',
  amount                  DECIMAL(10,2) NOT NULL,
  status                  TEXT DEFAULT 'pending',
  description             TEXT,
  issued_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
  due_date                DATE,
  stripe_payment_intent_id TEXT,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.15 MESSAGES (instructor-pupil chat)
CREATE TABLE messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  receiver_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  pupil_id        UUID REFERENCES pupils(id) ON DELETE SET NULL,
  pupil_name      TEXT DEFAULT '',
  body            TEXT NOT NULL,
  content         TEXT,
  is_from_instructor BOOLEAN DEFAULT true,
  timestamp       TIMESTAMPTZ NOT NULL DEFAULT now(),
  status          TEXT DEFAULT 'sent',
  is_locked       BOOLEAN DEFAULT false,
  is_edited       BOOLEAN DEFAULT false,
  is_deleted      BOOLEAN DEFAULT false,
  scheduled_for   TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.16 NOTIFICATIONS
CREATE TABLE app_notifications (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title           TEXT NOT NULL,
  body            TEXT DEFAULT '',
  type            TEXT DEFAULT '',
  is_read         BOOLEAN DEFAULT false,
  read            BOOLEAN DEFAULT false,
  timestamp       TIMESTAMPTZ NOT NULL DEFAULT now(),
  data            JSONB DEFAULT '{}',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.17 ENQUIRIES
CREATE TABLE enquiries (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id           UUID REFERENCES profiles(id) ON DELETE CASCADE,
  instructor_name         TEXT DEFAULT '',
  instructor_email        TEXT DEFAULT '',
  instructor_phone        TEXT DEFAULT '',
  pupil_id                UUID REFERENCES pupils(id) ON DELETE SET NULL,
  first_name              TEXT NOT NULL DEFAULT '',
  last_name               TEXT NOT NULL DEFAULT '',
  email                   TEXT NOT NULL DEFAULT '',
  phone                   TEXT NOT NULL DEFAULT '',
  address                 TEXT DEFAULT '',
  postcode                TEXT DEFAULT '',
  notes                   TEXT DEFAULT '',
  message                 TEXT DEFAULT '',
  experience_level        TEXT DEFAULT '',
  gearbox_preference      TEXT DEFAULT '',
  has_provisional_license BOOLEAN DEFAULT false,
  prior_practice_hours    INT DEFAULT 0,
  weekly_availability     TEXT DEFAULT '',
  weekly_availability_days JSONB DEFAULT '[]',
  availability            JSONB DEFAULT '[]',
  status                  TEXT DEFAULT 'pending',
  last_contacted          TIMESTAMPTZ,
  source                  TEXT,
  assigned_to_id          UUID REFERENCES profiles(id) ON DELETE SET NULL,
  isMockData              BOOLEAN DEFAULT false,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.18 TEST REPORTS
CREATE TABLE test_reports (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  pupil_id          UUID NOT NULL REFERENCES pupils(id) ON DELETE CASCADE,
  pupil_name        TEXT DEFAULT '',
  test_date         DATE NOT NULL,
  test_center_id    INT DEFAULT 0,
  test_center_name  TEXT,
  grade_level       TEXT DEFAULT 'Practical',
  result            TEXT DEFAULT 'pending',
  manoeuvres        JSONB DEFAULT '[]',
  scales_notes      TEXT DEFAULT '',
  aural_notes       TEXT DEFAULT '',
  notes             TEXT DEFAULT '',
  faults            INT DEFAULT 0,
  serious_faults    INT DEFAULT 0,
  dangerous_faults  INT DEFAULT 0,
  examiner_name     TEXT,
  examiner          TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.19 MILEAGE ENTRIES
CREATE TABLE mileage_entries (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  date            DATE NOT NULL DEFAULT CURRENT_DATE,
  miles           DECIMAL(10,2) NOT NULL,
  start_mileage   DECIMAL(10,2) DEFAULT 0,
  end_mileage     DECIMAL(10,2) DEFAULT 0,
  type            TEXT,
  notes           TEXT,
  description     TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.20 VEHICLES
CREATE TABLE vehicles (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  make                TEXT DEFAULT '',
  model               TEXT DEFAULT '',
  registration_plate  TEXT DEFAULT '',
  plate               TEXT DEFAULT '',
  registration        TEXT DEFAULT '',
  name                TEXT DEFAULT '',
  year                INT DEFAULT 0,
  color               TEXT DEFAULT '',
  gearbox             TEXT DEFAULT 'manual',
  is_automatic        BOOLEAN DEFAULT false,
  notes               TEXT,
  mot_expiry_date     TEXT,
  tax_expiry_date     TEXT,
  insurance_expiry_date TEXT,
  last_service_date   TEXT,
  current_mileage     INT DEFAULT 0,
  is_primary          BOOLEAN DEFAULT false,
  is_active           BOOLEAN DEFAULT true,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.21 PROGRESS CATEGORIES
CREATE TABLE progress_categories (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title           TEXT NOT NULL,
  name            TEXT DEFAULT '',
  description     TEXT DEFAULT '',
  order_index     INT DEFAULT 0,
  sort_order      INT DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.22 PROGRESS SKILLS
CREATE TABLE progress_skills (
  id                            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id                   UUID NOT NULL REFERENCES progress_categories(id) ON DELETE CASCADE,
  pupil_id                      UUID NOT NULL REFERENCES pupils(id) ON DELETE CASCADE,
  title                         TEXT NOT NULL,
  name                          TEXT DEFAULT '',
  description                   TEXT DEFAULT '',
  skill_level                   INT DEFAULT 0,
  score                         INT DEFAULT 0,
  order_index                   INT DEFAULT 0,
  requires_independent_driving  BOOLEAN DEFAULT false,
  created_at                    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at                    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.23 TEACHING RESOURCES
CREATE TABLE teaching_resources (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title               TEXT NOT NULL,
  type                TEXT DEFAULT 'document',
  category            TEXT,
  description         TEXT DEFAULT '',
  file_url            TEXT,
  file_type           TEXT DEFAULT 'link',
  video_link          TEXT,
  resource_link       TEXT,
  share_link          TEXT,
  visibility          TEXT NOT NULL DEFAULT 'private',
  selected_pupil_ids  JSONB DEFAULT '[]',
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.24 INSTRUCTOR ACTIVITY LOGS
CREATE TABLE instructor_activity_logs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  action          TEXT NOT NULL,
  details         TEXT DEFAULT '',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.25 PROMO CODES
CREATE TABLE promo_codes (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code              TEXT UNIQUE NOT NULL,
  description       TEXT DEFAULT '',
  discount_type     TEXT NOT NULL DEFAULT 'percentage' CHECK (discount_type IN ('percentage', 'fixed')),
  discount_value    DECIMAL(10,2) NOT NULL DEFAULT 0,
  discount_percent  INT DEFAULT 0,
  max_uses          INT DEFAULT 0,
  max_uses_per_user INT DEFAULT 0,
  current_uses      INT DEFAULT 0,
  used_count        INT DEFAULT 0,
  assigned_user_id  TEXT,
  valid_until       TEXT,
  expires_at        TIMESTAMPTZ,
  is_active         BOOLEAN DEFAULT true,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.26 BANNERS
CREATE TABLE banners (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title           TEXT NOT NULL DEFAULT '',
  description     TEXT,
  image_url       TEXT,
  link_url        TEXT,
  is_active       BOOLEAN DEFAULT true,
  sort_order      INT DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.27 APP SETTINGS (key-value store)
CREATE TABLE app_settings (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key             TEXT UNIQUE NOT NULL,
  value           TEXT NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.28 INSTRUCTOR LOCATIONS (GPS tracking)
CREATE TABLE instructor_locations (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  latitude        DECIMAL(10,7),
  longitude       DECIMAL(10,7),
  address         TEXT DEFAULT '',
  accuracy        DECIMAL(5,1),
  timestamp       TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_active       BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.29 INSTRUCTOR PAYMENT REQUESTS
CREATE TABLE instructor_payment_requests (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  pupil_id        UUID,
  amount          DECIMAL(10,2) NOT NULL,
  description     TEXT DEFAULT '',
  status          TEXT DEFAULT 'pending',
  notes           TEXT DEFAULT '',
  request_date    TIMESTAMPTZ NOT NULL DEFAULT now(),
  processed_date  TIMESTAMPTZ,
  reviewed_by     UUID REFERENCES profiles(id) ON DELETE SET NULL,
  reviewed_at     TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.30 INSTRUCTOR PAYMENTS (income - used by sync service)
CREATE TABLE instructor_payments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id   UUID REFERENCES profiles(id) ON DELETE CASCADE,
  pupil_id        UUID REFERENCES pupils(id) ON DELETE SET NULL,
  pupil_name      TEXT DEFAULT '',
  type            TEXT DEFAULT 'income',
  amount          DECIMAL(10,2) NOT NULL,
  description     TEXT DEFAULT '',
  date            TEXT,
  payment_date    TIMESTAMPTZ NOT NULL DEFAULT now(),
  payment_method  TEXT,
  payment_type    TEXT,
  category        TEXT,
  is_recurring    BOOLEAN DEFAULT false,
  receipt_url     TEXT,
  vendor_name     TEXT,
  is_reconciled   BOOLEAN DEFAULT false,
  tax_deductible  BOOLEAN DEFAULT true,
  status          TEXT DEFAULT 'pending',
  notes           TEXT DEFAULT '',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.31 PAYMENTS (pupil → instructor)
CREATE TABLE payments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  pupil_id        UUID REFERENCES pupils(id) ON DELETE SET NULL,
  lesson_id       UUID,
  type            TEXT DEFAULT 'income',
  amount          DECIMAL(10,2) NOT NULL,
  description     TEXT DEFAULT '',
  payment_method  TEXT,
  payment_date    TIMESTAMPTZ NOT NULL DEFAULT now(),
  status          TEXT DEFAULT 'pending',
  notes           TEXT DEFAULT '',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.32 EXPENSES (used by sync service)
CREATE TABLE expenses (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id   UUID REFERENCES profiles(id) ON DELETE CASCADE,
  type            TEXT DEFAULT 'expense',
  amount          DECIMAL(10,2) NOT NULL DEFAULT 0,
  description     TEXT DEFAULT '',
  date            TEXT,
  pupil_id        UUID,
  pupil_name      TEXT DEFAULT '',
  category        TEXT,
  payment_method  TEXT,
  payment_type    TEXT,
  is_recurring    BOOLEAN DEFAULT false,
  receipt_url     TEXT,
  vendor_name     TEXT,
  is_reconciled   BOOLEAN DEFAULT false,
  tax_deductible  BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.33 FEEDBACK
CREATE TABLE feedback (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type            TEXT DEFAULT '',
  rating          INT DEFAULT 0,
  message         TEXT NOT NULL DEFAULT '',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.34 APP CONTENT (privacy policy, terms, etc.)
CREATE TABLE app_content (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key             TEXT UNIQUE NOT NULL,
  title           TEXT NOT NULL DEFAULT '',
  content         TEXT NOT NULL DEFAULT '',
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2.35 CONTACT MESSAGES (web contact form)
CREATE TABLE contact_messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL,
  email           TEXT NOT NULL,
  message         TEXT NOT NULL,
  source          TEXT DEFAULT 'web',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================
-- PART 3: INDEXES
-- =============================================================
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_email ON profiles(email);

CREATE INDEX idx_pupils_instructor ON pupils(instructor_id);
CREATE INDEX idx_pupils_status ON pupils(status);
CREATE INDEX idx_pupils_email ON pupils(email);

CREATE INDEX idx_ipl_instructor ON instructor_pupil_links(instructor_id);
CREATE INDEX idx_ipl_pupil ON instructor_pupil_links(pupil_id);

CREATE INDEX idx_pupil_invitations_instructor ON pupil_invitations(instructor_id);
CREATE INDEX idx_pupil_invitations_email ON pupil_invitations(email);
CREATE INDEX idx_pupil_invitations_status ON pupil_invitations(status);

CREATE INDEX idx_pupil_invite_links_token ON pupil_invite_links(token);
CREATE INDEX idx_pupil_invite_links_instructor ON pupil_invite_links(instructor_id);

CREATE INDEX idx_submissions_link ON pupil_invite_submissions(link_id);
CREATE INDEX idx_submissions_status ON pupil_invite_submissions(status);

CREATE INDEX idx_lessons_instructor ON lessons(instructor_id);
CREATE INDEX idx_lessons_pupil ON lessons(pupil_id);
CREATE INDEX idx_lessons_date ON lessons(date);
CREATE INDEX idx_lessons_instructor_date ON lessons(instructor_id, date);
CREATE INDEX idx_lessons_status ON lessons(status);

CREATE INDEX idx_open_slots_instructor ON open_slots(instructor_id);
CREATE INDEX idx_open_slots_date ON open_slots(date);
CREATE INDEX idx_open_slots_available ON open_slots(instructor_id, date) WHERE is_booked = false;

CREATE INDEX idx_calendar_events_instructor ON calendar_events(instructor_id);
CREATE INDEX idx_calendar_events_date ON calendar_events(date);

CREATE INDEX idx_transactions_instructor ON transactions(instructor_id);
CREATE INDEX idx_transactions_pupil ON transactions(pupil_id);
CREATE INDEX idx_transactions_date ON transactions(date);
CREATE INDEX idx_transactions_type ON transactions(instructor_id, type);

CREATE INDEX idx_invoices_instructor ON invoices(instructor_id);
CREATE INDEX idx_invoices_pupil ON invoices(pupil_id);
CREATE INDEX idx_invoices_status ON invoices(status);

CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_receiver ON messages(receiver_id);
CREATE INDEX idx_messages_pupil ON messages(pupil_id);
CREATE INDEX idx_messages_created ON messages(created_at);
CREATE INDEX idx_messages_conversation ON messages(sender_id, receiver_id);

CREATE INDEX idx_notifications_user ON app_notifications(user_id);
CREATE INDEX idx_notifications_read ON app_notifications(user_id, is_read);

CREATE INDEX idx_enquiries_instructor ON enquiries(instructor_id);
CREATE INDEX idx_enquiries_status ON enquiries(status);

CREATE INDEX idx_test_reports_instructor ON test_reports(instructor_id);
CREATE INDEX idx_test_reports_pupil ON test_reports(pupil_id);

CREATE INDEX idx_mileage_instructor ON mileage_entries(instructor_id);
CREATE INDEX idx_mileage_date ON mileage_entries(date);

CREATE INDEX idx_vehicles_instructor ON vehicles(instructor_id);

CREATE INDEX idx_progress_categories_instructor ON progress_categories(instructor_id);
CREATE INDEX idx_progress_skills_pupil ON progress_skills(pupil_id);
CREATE INDEX idx_progress_skills_category ON progress_skills(category_id);

CREATE INDEX idx_teaching_resources_instructor ON teaching_resources(instructor_id);

CREATE INDEX idx_activity_logs_instructor ON instructor_activity_logs(instructor_id);
CREATE INDEX idx_activity_logs_created ON instructor_activity_logs(created_at);

CREATE INDEX idx_subscriptions_instructor ON instructor_subscriptions(instructor_id);
CREATE INDEX idx_subscriptions_status ON instructor_subscriptions(status);

CREATE INDEX idx_promo_codes_code ON promo_codes(code);

CREATE INDEX idx_locations_instructor ON instructor_locations(instructor_id);
CREATE INDEX idx_locations_timestamp ON instructor_locations(timestamp);

CREATE INDEX idx_payment_requests_instructor ON instructor_payment_requests(instructor_id);
CREATE INDEX idx_payment_requests_status ON instructor_payment_requests(status);

CREATE INDEX idx_instructor_payments_instructor ON instructor_payments(instructor_id);
CREATE INDEX idx_payments_instructor ON payments(instructor_id);
CREATE INDEX idx_payments_pupil ON payments(pupil_id);
CREATE INDEX idx_expenses_instructor ON expenses(instructor_id);

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

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_pupils_updated_at BEFORE UPDATE ON pupils FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_lessons_updated_at BEFORE UPDATE ON lessons FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_open_slots_updated_at BEFORE UPDATE ON open_slots FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_calendar_events_updated_at BEFORE UPDATE ON calendar_events FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_enquiries_updated_at BEFORE UPDATE ON enquiries FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_test_reports_updated_at BEFORE UPDATE ON test_reports FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_vehicles_updated_at BEFORE UPDATE ON vehicles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_progress_categories_updated_at BEFORE UPDATE ON progress_categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_progress_skills_updated_at BEFORE UPDATE ON progress_skills FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_teaching_resources_updated_at BEFORE UPDATE ON teaching_resources FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_subscription_plans_updated_at BEFORE UPDATE ON subscription_plans FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_pupil_invitations_updated_at BEFORE UPDATE ON pupil_invitations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_promo_codes_updated_at BEFORE UPDATE ON promo_codes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_banners_updated_at BEFORE UPDATE ON banners FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_instructor_payment_requests_updated_at BEFORE UPDATE ON instructor_payment_requests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_app_settings_updated_at BEFORE UPDATE ON app_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_app_content_updated_at BEFORE UPDATE ON app_content FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================
-- PART 5: ROW LEVEL SECURITY (RLS)
-- =============================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE pupils ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructor_pupil_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE pupil_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE pupil_invite_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE pupil_invite_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE open_slots ENABLE ROW LEVEL SECURITY;
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
ALTER TABLE instructor_subscriptions ENABLE ROW LEVEL SECURITY;
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
ALTER TABLE contact_messages ENABLE ROW LEVEL SECURITY;

-- Security definer function to check admin role (bypasses RLS recursion)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql SECURITY DEFINER STABLE
AS $$
  SELECT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
$$;

-- PROFILES
CREATE POLICY "profiles_insert" ON profiles FOR INSERT WITH CHECK (true);
CREATE POLICY "profiles_read_own" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "profiles_read_instructor_pupils" ON profiles FOR SELECT USING (auth.uid() IN (SELECT instructor_id FROM instructor_pupil_links WHERE pupil_id = id));
CREATE POLICY "profiles_update_own" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "profiles_admin_all" ON profiles FOR ALL USING (public.is_admin());

-- PUPILS
CREATE POLICY "pupils_insert" ON pupils FOR INSERT WITH CHECK (true);
CREATE POLICY "pupils_instructor_all" ON pupils FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "pupils_read_own" ON pupils FOR SELECT USING (id = auth.uid());
CREATE POLICY "pupils_admin_all" ON pupils FOR ALL USING (public.is_admin());

-- INSTRUCTOR-PUPIL LINKS
CREATE POLICY "links_insert" ON instructor_pupil_links FOR INSERT WITH CHECK (true);
CREATE POLICY "links_instructor_all" ON instructor_pupil_links FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "links_pupil_read" ON instructor_pupil_links FOR SELECT USING (pupil_id = auth.uid());
CREATE POLICY "links_admin_all" ON instructor_pupil_links FOR ALL USING (public.is_admin());

-- PUPIL INVITATIONS
CREATE POLICY "invitations_instructor_all" ON pupil_invitations FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "invitations_pupil_read" ON pupil_invitations FOR SELECT USING (email = (SELECT email FROM profiles WHERE id = auth.uid()));
CREATE POLICY "invitations_admin_all" ON pupil_invitations FOR ALL USING (public.is_admin());

-- PUPIL INVITE LINKS
CREATE POLICY "invite_links_instructor_all" ON pupil_invite_links FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "invite_links_admin_all" ON pupil_invite_links FOR ALL USING (public.is_admin());

-- PUPIL INVITE SUBMISSIONS (public insert for web form)
CREATE POLICY "submissions_insert" ON pupil_invite_submissions FOR INSERT WITH CHECK (true);
CREATE POLICY "submissions_instructor_all" ON pupil_invite_submissions FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "submissions_admin_all" ON pupil_invite_submissions FOR ALL USING (public.is_admin());
CREATE POLICY "submissions_pupil_read" ON pupil_invite_submissions FOR SELECT USING (email = (SELECT email FROM profiles WHERE id = auth.uid()));

-- LESSONS
CREATE POLICY "lessons_instructor_all" ON lessons FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "lessons_pupil_read" ON lessons FOR SELECT USING (pupil_id = auth.uid());
CREATE POLICY "lessons_admin_all" ON lessons FOR ALL USING (public.is_admin());

-- OPEN SLOTS
CREATE POLICY "slots_instructor_all" ON open_slots FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "slots_pupil_read_available" ON open_slots FOR SELECT USING (is_booked = false AND status = 'available');
CREATE POLICY "slots_admin_all" ON open_slots FOR ALL USING (public.is_admin());

-- CALENDAR EVENTS
CREATE POLICY "calendar_events_instructor_all" ON calendar_events FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "calendar_events_admin_all" ON calendar_events FOR ALL USING (public.is_admin());

-- EVENTS (admin announcements)
CREATE POLICY "events_admin_all" ON events FOR ALL USING (public.is_admin());
CREATE POLICY "events_public_read" ON events FOR SELECT USING (is_published = true);

-- TRANSACTIONS
CREATE POLICY "transactions_instructor_all" ON transactions FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "transactions_pupil_read" ON transactions FOR SELECT USING (pupil_id = auth.uid());
CREATE POLICY "transactions_admin_all" ON transactions FOR ALL USING (public.is_admin());

-- INVOICES
CREATE POLICY "invoices_instructor_all" ON invoices FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "invoices_pupil_read" ON invoices FOR SELECT USING (pupil_id = auth.uid());
CREATE POLICY "invoices_admin_all" ON invoices FOR ALL USING (public.is_admin());

-- MESSAGES
CREATE POLICY "messages_participant" ON messages FOR ALL USING (auth.uid() IN (sender_id, receiver_id));
CREATE POLICY "messages_admin_all" ON messages FOR ALL USING (public.is_admin());

-- NOTIFICATIONS
CREATE POLICY "notifications_user" ON app_notifications FOR ALL USING (user_id = auth.uid());

-- ENQUIRIES
CREATE POLICY "enquiries_instructor_all" ON enquiries FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "enquiries_pupil_read" ON enquiries FOR SELECT USING (pupil_id = auth.uid());
CREATE POLICY "enquiries_admin_all" ON enquiries FOR ALL USING (public.is_admin());

-- TEST REPORTS
CREATE POLICY "test_reports_instructor_all" ON test_reports FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "test_reports_pupil_read" ON test_reports FOR SELECT USING (pupil_id = auth.uid());
CREATE POLICY "test_reports_admin_all" ON test_reports FOR ALL USING (public.is_admin());

-- MILEAGE
CREATE POLICY "mileage_instructor_all" ON mileage_entries FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "mileage_admin_all" ON mileage_entries FOR ALL USING (public.is_admin());

-- VEHICLES
CREATE POLICY "vehicles_instructor_all" ON vehicles FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "vehicles_admin_all" ON vehicles FOR ALL USING (public.is_admin());

-- PROGRESS CATEGORIES
CREATE POLICY "progress_categories_instructor_all" ON progress_categories FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "progress_categories_admin_all" ON progress_categories FOR ALL USING (public.is_admin());

-- PROGRESS SKILLS
CREATE POLICY "progress_skills_instructor_all" ON progress_skills FOR ALL USING (category_id IN (SELECT id FROM progress_categories WHERE instructor_id = auth.uid()));
CREATE POLICY "progress_skills_pupil_read" ON progress_skills FOR SELECT USING (pupil_id = auth.uid());
CREATE POLICY "progress_skills_admin_all" ON progress_skills FOR ALL USING (public.is_admin());

-- TEACHING RESOURCES
CREATE POLICY "resources_instructor_all" ON teaching_resources FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "resources_pupil_read" ON teaching_resources FOR SELECT USING (visibility = 'public' OR (visibility = 'selective' AND selected_pupil_ids ? (SELECT id::text FROM profiles WHERE id = auth.uid())));
CREATE POLICY "resources_admin_all" ON teaching_resources FOR ALL USING (public.is_admin());

-- ACTIVITY LOGS
CREATE POLICY "activity_logs_instructor_all" ON instructor_activity_logs FOR ALL USING (instructor_id = auth.uid());

-- SUBSCRIPTIONS
CREATE POLICY "subscriptions_instructor_all" ON instructor_subscriptions FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "subscriptions_admin_all" ON instructor_subscriptions FOR ALL USING (public.is_admin());

-- SUBSCRIPTION PLANS
CREATE POLICY "plans_read_all" ON subscription_plans FOR SELECT USING (true);
CREATE POLICY "plans_admin_all" ON subscription_plans FOR ALL USING (public.is_admin());

-- PROMO CODES
CREATE POLICY "promo_codes_admin_all" ON promo_codes FOR ALL USING (public.is_admin());

-- BANNERS
CREATE POLICY "banners_read_all" ON banners FOR SELECT USING (is_active = true);
CREATE POLICY "banners_admin_all" ON banners FOR ALL USING (public.is_admin());

-- APP SETTINGS
CREATE POLICY "app_settings_read_all" ON app_settings FOR SELECT USING (true);
CREATE POLICY "app_settings_admin_all" ON app_settings FOR ALL USING (public.is_admin());

-- INSTRUCTOR LOCATIONS
CREATE POLICY "locations_instructor_all" ON instructor_locations FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "locations_admin_read" ON instructor_locations FOR SELECT USING (public.is_admin());

-- INSTRUCTOR PAYMENT REQUESTS
CREATE POLICY "payment_requests_instructor_all" ON instructor_payment_requests FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "payment_requests_admin_all" ON instructor_payment_requests FOR ALL USING (public.is_admin());

-- INSTRUCTOR PAYMENTS
CREATE POLICY "instructor_payments_instructor_all" ON instructor_payments FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "instructor_payments_admin_all" ON instructor_payments FOR ALL USING (public.is_admin());

-- PAYMENTS
CREATE POLICY "payments_instructor_all" ON payments FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "payments_pupil_read" ON payments FOR SELECT USING (pupil_id = auth.uid());
CREATE POLICY "payments_admin_all" ON payments FOR ALL USING (public.is_admin());

-- EXPENSES
CREATE POLICY "expenses_instructor_all" ON expenses FOR ALL USING (instructor_id = auth.uid());
CREATE POLICY "expenses_admin_all" ON expenses FOR ALL USING (public.is_admin());

-- FEEDBACK
CREATE POLICY "feedback_insert" ON feedback FOR INSERT WITH CHECK (true);
CREATE POLICY "feedback_admin_read" ON feedback FOR SELECT USING (public.is_admin());

-- APP CONTENT
CREATE POLICY "app_content_read" ON app_content FOR SELECT USING (true);
CREATE POLICY "app_content_admin_all" ON app_content FOR ALL USING (public.is_admin());

-- CONTACT MESSAGES
CREATE POLICY "contact_insert_anon" ON contact_messages FOR INSERT WITH CHECK (true);
CREATE POLICY "contact_admin_all" ON contact_messages FOR ALL USING (public.is_admin());

-- =============================================================
-- PART 6: GRANTS (ensure all roles have access)
-- =============================================================
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;

-- =============================================================
-- PART 7: AUTH TRIGGER (auto-create profile on signup)
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
-- PART 8: SEED DATA
-- =============================================================

-- Default subscription plans
INSERT INTO subscription_plans (name, price, duration_months, features, is_free_tier, is_active, sort_order) VALUES
  ('Free Trial', 0, 2, '["Up to 5 pupils", "Basic diary", "Manual payment tracking"]', true, true, 0),
  ('Starter', 9.99, 1, '["Up to 10 pupils", "Smart diary", "Payment tracking", "Pupil messaging"]', false, true, 1),
  ('Professional', 19.99, 1, '["Unlimited pupils", "Smart diary with slots", "Full financial reports", "Pupil messaging & portal", "Progress tracking", "Test reports"]', false, true, 2),
  ('Premium', 29.99, 1, '["Everything in Professional", "Online booking", "Route planning", "Priority support", "Custom branding", "API access", "Multi-instructor support"]', false, true, 3)
ON CONFLICT DO NOTHING;

-- Default app settings
INSERT INTO app_settings (key, value) VALUES
  ('platform_name', '"Lesson Tracker Pro"'),
  ('platform_fee_percentage', '2.9'),
  ('free_trial_days', '60'),
  ('default_currency', '"GBP"'),
  ('support_email', '"support@lessontrackerpro.com"')
ON CONFLICT (key) DO NOTHING;

-- Default banners
INSERT INTO banners (title, description, is_active, sort_order) VALUES
  ('Welcome to Lesson Tracker Pro', 'Your all-in-one driving school management platform', true, 0)
ON CONFLICT DO NOTHING;

-- =============================================================
-- SCHEMA COMPLETE - 35 tables, all policies, indexes, triggers
-- =============================================================
