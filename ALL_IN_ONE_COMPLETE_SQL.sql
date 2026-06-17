-- ============================================
-- ALL-IN-ONE COMPLETE SQL for Lesson Tracker Pro
-- Supabase Database Setup
-- Run this entire script in your Supabase SQL Editor
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. profiles (extends Supabase auth.users)
-- ============================================
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  phone TEXT,
  role TEXT NOT NULL CHECK (role IN ('instructor', 'pupil', 'admin')),
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  email_verified BOOLEAN DEFAULT FALSE
);

-- ============================================
-- 2. instructors (Instructor-specific data)
-- ============================================
CREATE TABLE IF NOT EXISTS instructors (
  id UUID REFERENCES profiles(id) PRIMARY KEY,
  business_name TEXT,
  instructor_title TEXT,
  hourly_rate DECIMAL(10,2) DEFAULT 35.00,
  currency TEXT DEFAULT 'GBP',
  location_lat DECIMAL(10,8),
  location_lng DECIMAL(10,8),
  location_address TEXT,
  service_radius_km INTEGER DEFAULT 20,
  bio TEXT,
  certifications TEXT[],
  languages TEXT[],
  vehicle_make TEXT,
  vehicle_model TEXT,
  vehicle_year INTEGER,
  vehicle_plate TEXT,
  availability JSONB,
  is_verified BOOLEAN DEFAULT FALSE,
  rating DECIMAL(3,2),
  review_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 3. pupils (Pupil-specific data)
-- ============================================
CREATE TABLE IF NOT EXISTS pupils (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  instructor_id UUID REFERENCES instructors(id),
  email TEXT,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  address TEXT,
  postcode TEXT,
  gearbox_preference TEXT CHECK (gearbox_preference IN ('manual', 'automatic', 'any')),
  learning_goals TEXT[],
  experience_level TEXT CHECK (experience_level IN ('beginner', 'intermediate', 'advanced')),
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  test_date DATE,
  preferred_days TEXT[],
  preferred_times TEXT[],
  test_progress JSONB DEFAULT '{}',
  status TEXT CHECK (status IN ('current', 'waiting', 'passed', 'archived')) DEFAULT 'current',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 4. instructor_pupil_links (Many-to-many)
-- ============================================
CREATE TABLE IF NOT EXISTS instructor_pupil_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  pupil_id UUID REFERENCES pupils(id) ON DELETE CASCADE,
  status TEXT CHECK (status IN ('pending', 'waiting', 'active', 'inactive', 'completed')) DEFAULT 'pending',
  hourly_rate DECIMAL(10,2),
  linked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(instructor_id, pupil_id)
);

-- ============================================
-- 5. lessons (Lesson bookings)
-- ============================================
CREATE TABLE IF NOT EXISTS lessons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  pupil_id UUID REFERENCES pupils(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  time TEXT NOT NULL,
  duration INTEGER NOT NULL,
  pickup_location TEXT,
  dropoff_location TEXT,
  lesson_type TEXT CHECK (lesson_type IN ('standard', 'motorway', 'pass_plus', 'mock_test', 'refresher')),
  notes TEXT,
  status TEXT CHECK (status IN ('scheduled', 'completed', 'cancelled', 'no_show')) DEFAULT 'scheduled',
  paid BOOLEAN DEFAULT FALSE,
  amount DECIMAL(10,2),
  rate DECIMAL(10,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 6. payments (Financial transactions)
-- ============================================
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  pupil_id UUID REFERENCES pupils(id) ON DELETE CASCADE,
  lesson_id UUID REFERENCES lessons(id) ON DELETE SET NULL,
  type TEXT CHECK (type IN ('income', 'expense', 'refund')) NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  description TEXT,
  payment_method TEXT CHECK (payment_method IN ('cash', 'card', 'bank_transfer', 'online')),
  status TEXT CHECK (status IN ('pending', 'completed', 'failed', 'refunded')) DEFAULT 'pending',
  transaction_reference TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 7. enquiries (Pupil enquiries to instructors)
-- ============================================
CREATE TABLE IF NOT EXISTS enquiries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  pupil_id UUID REFERENCES pupils(id) ON DELETE SET NULL,
  name TEXT,
  first_name TEXT,
  last_name TEXT,
  email TEXT,
  phone TEXT,
  address TEXT,
  postcode TEXT,
  notes TEXT,
  message TEXT,
  experience_level TEXT CHECK (experience_level IN ('beginner', 'intermediate', 'advanced')),
  gearbox_preference TEXT CHECK (gearbox_preference IN ('manual', 'automatic', 'any')),
  gearbox_type TEXT,
  has_provisional_license BOOLEAN DEFAULT FALSE,
  prior_practice_hours INTEGER DEFAULT 0,
  weekly_availability TEXT[],
  status TEXT CHECK (status IN ('pending', 'contacted', 'interested', 'converted', 'not_interested')) DEFAULT 'pending',
  last_contacted TIMESTAMP WITH TIME ZONE,
  source TEXT,
  assigned_to_id UUID REFERENCES profiles(id),
  is_mock_data BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 8. messages (In-app messaging)
-- ============================================
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  receiver_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  lesson_id UUID REFERENCES lessons(id) ON DELETE SET NULL,
  content TEXT NOT NULL,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 9. open_slots (Instructor available slots)
-- ============================================
CREATE TABLE IF NOT EXISTS open_slots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  start_time TEXT NOT NULL,
  duration INTEGER NOT NULL,
  location TEXT,
  is_booked BOOLEAN DEFAULT FALSE,
  booked_by UUID REFERENCES pupils(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 10. progress_categories (Skill categories)
-- ============================================
CREATE TABLE IF NOT EXISTS progress_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 11. progress_skills (Individual skills)
-- ============================================
CREATE TABLE IF NOT EXISTS progress_skills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID REFERENCES progress_categories(id) ON DELETE CASCADE,
  pupil_id UUID REFERENCES pupils(id) ON DELETE CASCADE,
  skill_name TEXT NOT NULL,
  skill_level INTEGER CHECK (skill_level >= 1 AND skill_level <= 5) DEFAULT 1,
  notes TEXT,
  last_practiced DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 12. teaching_resources (Instructor materials)
-- ============================================
CREATE TABLE IF NOT EXISTS teaching_resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  type TEXT CHECK (type IN ('document', 'video', 'link')) NOT NULL,
  category TEXT NOT NULL,
  description TEXT,
  video_link TEXT,
  resource_link TEXT,
  share_link TEXT,
  visibility TEXT CHECK (visibility IN ('private', 'public', 'selective')) DEFAULT 'private',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 13. resource_pupil_access (Selective access)
-- ============================================
CREATE TABLE IF NOT EXISTS resource_pupil_access (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resource_id UUID REFERENCES teaching_resources(id) ON DELETE CASCADE,
  pupil_id UUID REFERENCES pupils(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(resource_id, pupil_id)
);

-- ============================================
-- 14. test_reports (Driving test reports)
-- ============================================
CREATE TABLE IF NOT EXISTS test_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pupil_id UUID REFERENCES pupils(id) ON DELETE CASCADE,
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  test_date DATE NOT NULL,
  test_center_name TEXT,
  test_center_id INTEGER,
  result TEXT CHECK (result IN ('pass', 'fail', 'pending', 'did_not_attend', 'cancelled')) NOT NULL,
  grade_level TEXT,
  manoeuvres TEXT[],
  scales_notes TEXT,
  aural_notes TEXT,
  notes TEXT,
  examiner_name TEXT,
  faults INTEGER DEFAULT 0,
  serious_faults INTEGER DEFAULT 0,
  dangerous_faults INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 15. invoices (Payment requests)
-- ============================================
CREATE TABLE IF NOT EXISTS invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  pupil_id UUID REFERENCES pupils(id) ON DELETE CASCADE,
  invoice_number TEXT UNIQUE NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  description TEXT,
  due_date DATE,
  status TEXT CHECK (status IN ('pending', 'paid', 'overdue', 'cancelled')) DEFAULT 'pending',
  payment_link TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 16. mileage_entries (Vehicle mileage)
-- ============================================
CREATE TABLE IF NOT EXISTS mileage_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  miles DECIMAL(10,2) NOT NULL,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 17. app_notifications (In-app notifications)
-- ============================================
CREATE TABLE IF NOT EXISTS app_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT CHECK (type IN ('info', 'success', 'warning', 'error')) DEFAULT 'info',
  read BOOLEAN DEFAULT FALSE,
  action_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 18. banners (Promotions/announcements)
-- ============================================
CREATE TABLE IF NOT EXISTS banners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  action_url TEXT,
  type TEXT CHECK (type IN ('promotion', 'announcement', 'info', 'warning')) DEFAULT 'info',
  is_active BOOLEAN DEFAULT TRUE,
  start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  end_date TIMESTAMP WITH TIME ZONE,
  target_audience TEXT CHECK (target_audience IN ('all', 'instructors', 'pupils')) DEFAULT 'all',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 19. vehicles (Instructor vehicle management)
-- ============================================
CREATE TABLE IF NOT EXISTS vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  make TEXT NOT NULL,
  model TEXT NOT NULL,
  year INTEGER,
  plate TEXT UNIQUE NOT NULL,
  color TEXT,
  is_primary BOOLEAN DEFAULT FALSE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 20. calendar_events (Instructor calendar)
-- ============================================
CREATE TABLE IF NOT EXISTS calendar_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  location TEXT,
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE,
  is_all_day BOOLEAN DEFAULT FALSE,
  sync_to_external_calendar BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 21. user_settings (App settings per user)
-- ============================================
CREATE TABLE IF NOT EXISTS user_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  key TEXT NOT NULL,
  value JSONB NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, key)
);

-- ============================================
-- 22. pupil_invitations (Invitation codes)
-- ============================================
CREATE TABLE IF NOT EXISTS pupil_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  postcode TEXT,
  invitation_code TEXT NOT NULL,
  status TEXT CHECK (status IN ('pending', 'approved', 'accepted', 'expired')) DEFAULT 'pending',
  source TEXT DEFAULT 'manual',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  approved_at TIMESTAMP WITH TIME ZONE,
  accepted_at TIMESTAMP WITH TIME ZONE
);

-- ============================================
-- 23. subscription_plans (SaaS plans)
-- ============================================
CREATE TABLE IF NOT EXISTS subscription_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  price DECIMAL(10,2) NOT NULL DEFAULT 0,
  duration_months INTEGER NOT NULL DEFAULT 1,
  features JSONB DEFAULT '[]',
  is_free_tier BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 24. instructor_subscriptions (Active subs)
-- ============================================
CREATE TABLE IF NOT EXISTS instructor_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  plan_id UUID REFERENCES subscription_plans(id),
  start_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  end_date TIMESTAMP WITH TIME ZONE,
  status TEXT CHECK (status IN ('active', 'expired', 'cancelled', 'trial')) DEFAULT 'active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 25. promo_codes (Discount codes)
-- ============================================
CREATE TABLE IF NOT EXISTS promo_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  discount_percent INTEGER NOT NULL DEFAULT 0 CHECK (discount_percent >= 0 AND discount_percent <= 100),
  max_uses INTEGER DEFAULT 0,
  used_count INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  valid_until TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 26. instructor_payment_requests (Payouts)
-- ============================================
CREATE TABLE IF NOT EXISTS instructor_payment_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  request_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status TEXT CHECK (status IN ('pending', 'approved', 'paid', 'rejected')) DEFAULT 'pending',
  notes TEXT,
  processed_date TIMESTAMP WITH TIME ZONE
);

-- ============================================
-- 27. instructor_activity_logs (Monitoring)
-- ============================================
CREATE TABLE IF NOT EXISTS instructor_activity_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  details TEXT,
  ip_address TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 28. instructor_locations (GPS tracking)
-- ============================================
CREATE TABLE IF NOT EXISTS instructor_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  latitude DECIMAL(10,8) NOT NULL,
  longitude DECIMAL(10,8) NOT NULL,
  accuracy DECIMAL(10,2),
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 29. support_conversations (Support tickets)
-- ============================================
CREATE TABLE IF NOT EXISTS support_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  status TEXT CHECK (status IN ('open', 'closed', 'pending')) DEFAULT 'open',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 30. app_settings (Global app settings)
-- ============================================
CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

-- ============================================
-- 31. app_content (Dynamic content)
-- ============================================
CREATE TABLE IF NOT EXISTS app_content (
  key TEXT PRIMARY KEY,
  content TEXT NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 32. events (Admin events)
-- ============================================
CREATE TABLE IF NOT EXISTS events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT TRUE
);

-- ============================================
-- 33. feedback (User feedback)
-- ============================================
CREATE TABLE IF NOT EXISTS feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  type TEXT DEFAULT 'General',
  rating INTEGER DEFAULT 0,
  message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================

-- profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Instructors can view linked pupils"
  ON profiles FOR SELECT
  USING (
    auth.uid() IN (
      SELECT instructor_id FROM instructor_pupil_links WHERE pupil_id = profiles.id
    )
  );

-- instructors
ALTER TABLE instructors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can view own data"
  ON instructors FOR ALL
  USING (auth.uid() = id);

CREATE POLICY "Pupils can view linked instructors"
  ON instructors FOR SELECT
  USING (
    auth.uid() IN (
      SELECT pupil_id FROM instructor_pupil_links WHERE instructor_id = instructors.id
    )
  );

CREATE POLICY "Public can view verified instructors for discovery"
  ON instructors FOR SELECT
  USING (is_verified = TRUE);

-- pupils
ALTER TABLE pupils ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Pupils can view own data"
  ON pupils FOR ALL
  USING (auth.uid() = profile_id OR auth.uid() = id);

CREATE POLICY "Instructors can view linked pupils"
  ON pupils FOR SELECT
  USING (
    auth.uid() IN (
      SELECT instructor_id FROM instructor_pupil_links WHERE pupil_id = pupils.id
    )
  );

-- instructor_pupil_links
ALTER TABLE instructor_pupil_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can view own links"
  ON instructor_pupil_links FOR ALL
  USING (auth.uid() = instructor_id);

CREATE POLICY "Pupils can view own links"
  ON instructor_pupil_links FOR ALL
  USING (auth.uid() = pupil_id);

-- lessons
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can view own lessons"
  ON lessons FOR ALL
  USING (auth.uid() = instructor_id);

CREATE POLICY "Pupils can view own lessons"
  ON lessons FOR ALL
  USING (auth.uid() = pupil_id);

-- payments
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can view own payments"
  ON payments FOR ALL
  USING (auth.uid() = instructor_id);

CREATE POLICY "Pupils can view own payments"
  ON payments FOR SELECT
  USING (auth.uid() = pupil_id);

-- enquiries
ALTER TABLE enquiries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can view enquiries sent to them"
  ON enquiries FOR ALL
  USING (auth.uid() = instructor_id);

CREATE POLICY "Pupils can view own enquiries"
  ON enquiries FOR ALL
  USING (auth.uid() = pupil_id);

CREATE POLICY "Public can create enquiries"
  ON enquiries FOR INSERT
  WITH CHECK (true);

-- messages
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view messages they sent or received"
  ON messages FOR SELECT
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can insert messages they send"
  ON messages FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update messages they sent"
  ON messages FOR UPDATE
  USING (auth.uid() = sender_id);

-- open_slots
ALTER TABLE open_slots ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can manage own slots"
  ON open_slots FOR ALL
  USING (auth.uid() = instructor_id);

CREATE POLICY "Pupils can view available slots"
  ON open_slots FOR SELECT
  USING (is_booked = FALSE);

-- progress_categories
ALTER TABLE progress_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can manage own categories"
  ON progress_categories FOR ALL
  USING (auth.uid() = instructor_id);

CREATE POLICY "Pupils can view linked instructor categories"
  ON progress_categories FOR SELECT
  USING (
    auth.uid() IN (
      SELECT pupil_id FROM instructor_pupil_links WHERE instructor_id = progress_categories.instructor_id
    )
  );

-- progress_skills
ALTER TABLE progress_skills ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can view linked pupil skills"
  ON progress_skills FOR ALL
  USING (
    auth.uid() IN (
      SELECT instructor_id FROM instructor_pupil_links WHERE pupil_id = progress_skills.pupil_id
    )
  );

CREATE POLICY "Pupils can view own skills"
  ON progress_skills FOR SELECT
  USING (auth.uid() = pupil_id);

-- teaching_resources
ALTER TABLE teaching_resources ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can manage own resources"
  ON teaching_resources FOR ALL
  USING (auth.uid() = instructor_id);

CREATE POLICY "Pupils can view linked instructor public resources"
  ON teaching_resources FOR SELECT
  USING (
    visibility = 'public' AND
    auth.uid() IN (
      SELECT pupil_id FROM instructor_pupil_links WHERE instructor_id = teaching_resources.instructor_id
    )
  );

CREATE POLICY "Pupils can view selectively shared resources"
  ON teaching_resources FOR SELECT
  USING (
    visibility = 'selective' AND
    auth.uid() IN (
      SELECT pupil_id FROM resource_pupil_access WHERE resource_id = teaching_resources.id
    )
  );

-- resource_pupil_access
ALTER TABLE resource_pupil_access ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can manage resource access"
  ON resource_pupil_access FOR ALL
  USING (
    auth.uid() IN (
      SELECT instructor_id FROM teaching_resources WHERE id = resource_id
    )
  );

CREATE POLICY "Pupils can view their resource access"
  ON resource_pupil_access FOR SELECT
  USING (auth.uid() = pupil_id);

-- test_reports
ALTER TABLE test_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can view linked pupil reports"
  ON test_reports FOR ALL
  USING (auth.uid() = instructor_id);

CREATE POLICY "Pupils can view own reports"
  ON test_reports FOR SELECT
  USING (auth.uid() = pupil_id);

-- invoices
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can manage own invoices"
  ON invoices FOR ALL
  USING (auth.uid() = instructor_id);

CREATE POLICY "Pupils can view own invoices"
  ON invoices FOR SELECT
  USING (auth.uid() = pupil_id);

-- mileage_entries
ALTER TABLE mileage_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can manage own mileage"
  ON mileage_entries FOR ALL
  USING (auth.uid() = instructor_id);

-- app_notifications
ALTER TABLE app_notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications"
  ON app_notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
  ON app_notifications FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notifications"
  ON app_notifications FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own notifications"
  ON app_notifications FOR DELETE
  USING (auth.uid() = user_id);

-- banners (public read, admin write)
ALTER TABLE banners ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view active banners"
  ON banners FOR SELECT
  USING (
    is_active = TRUE AND
    (start_date <= NOW() OR start_date IS NULL) AND
    (end_date >= NOW() OR end_date IS NULL)
  );

-- vehicles
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can manage own vehicles"
  ON vehicles FOR ALL
  USING (auth.uid() = instructor_id);

-- calendar_events
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can manage own calendar events"
  ON calendar_events FOR ALL
  USING (auth.uid() = instructor_id);

-- user_settings
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own settings"
  ON user_settings FOR ALL
  USING (auth.uid() = user_id);

-- pupil_invitations
ALTER TABLE pupil_invitations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can manage own invitations"
  ON pupil_invitations FOR ALL
  USING (auth.uid() = instructor_id);

CREATE POLICY "Public can read invitations by code"
  ON pupil_invitations FOR SELECT
  USING (true);

-- subscription_plans
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view active plans"
  ON subscription_plans FOR SELECT
  USING (is_active = TRUE);

-- instructor_subscriptions
ALTER TABLE instructor_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can view own subscriptions"
  ON instructor_subscriptions FOR SELECT
  USING (auth.uid() = instructor_id);

CREATE POLICY "Instructors can insert own subscriptions"
  ON instructor_subscriptions FOR INSERT
  WITH CHECK (auth.uid() = instructor_id);

-- promo_codes
ALTER TABLE promo_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can validate promo codes"
  ON promo_codes FOR SELECT
  USING (is_active = TRUE AND (valid_until IS NULL OR valid_until >= NOW()));

-- instructor_payment_requests
ALTER TABLE instructor_payment_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can view own payment requests"
  ON instructor_payment_requests FOR SELECT
  USING (auth.uid() = instructor_id);

CREATE POLICY "Instructors can create payment requests"
  ON instructor_payment_requests FOR INSERT
  WITH CHECK (auth.uid() = instructor_id);

-- instructor_activity_logs
ALTER TABLE instructor_activity_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view all activity logs"
  ON instructor_activity_logs FOR SELECT
  USING (true);

CREATE POLICY "System can insert activity logs"
  ON instructor_activity_logs FOR INSERT
  WITH CHECK (true);

-- instructor_locations
ALTER TABLE instructor_locations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view all locations"
  ON instructor_locations FOR SELECT
  USING (true);

CREATE POLICY "Instructors can insert own location"
  ON instructor_locations FOR INSERT
  WITH CHECK (auth.uid() = instructor_id);

-- support_conversations
ALTER TABLE support_conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can view own conversations"
  ON support_conversations FOR ALL
  USING (auth.uid() = instructor_id);

-- app_settings
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view app settings"
  ON app_settings FOR SELECT
  USING (true);

-- app_content
ALTER TABLE app_content ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view app content"
  ON app_content FOR SELECT
  USING (true);

-- events
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view active events"
  ON events FOR SELECT
  USING (is_active = TRUE);

-- ============================================
-- DATABASE FUNCTIONS
-- ============================================

-- Function: Create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role, email_verified)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'role', 'pupil'),
    NEW.email_confirmed_at IS NOT NULL
  );

  -- Create role-specific profile
  IF NEW.raw_user_meta_data->>'role' = 'instructor' THEN
    INSERT INTO public.instructors (id)
    VALUES (NEW.id);
  ELSIF NEW.raw_user_meta_data->>'role' = 'pupil' THEN
    INSERT INTO public.pupils (id, profile_id)
    VALUES (NEW.id, NEW.id);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function: Update email verification status
CREATE OR REPLACE FUNCTION public.update_email_verification()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.profiles
  SET email_verified = NEW.email_confirmed_at IS NOT NULL
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_email_confirmed ON auth.users;
CREATE TRIGGER on_email_confirmed
  AFTER UPDATE OF email_confirmed_at ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.update_email_verification();

-- Function: Auto-generate invoice number
CREATE OR REPLACE FUNCTION public.generate_invoice_number()
RETURNS TRIGGER AS $$
DECLARE
  invoice_num TEXT;
  seq_num INTEGER;
BEGIN
  seq_num := nextval('invoice_sequence');
  invoice_num := 'INV-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(seq_num::TEXT, 4, '0');
  NEW.invoice_number := invoice_num;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Sequence for invoice numbering
CREATE SEQUENCE IF NOT EXISTS invoice_sequence START 1;

DROP TRIGGER IF EXISTS on_invoice_created ON invoices;
CREATE TRIGGER on_invoice_created
  BEFORE INSERT ON invoices
  FOR EACH ROW EXECUTE FUNCTION public.generate_invoice_number();

-- Function: Update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to key tables
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_instructors_updated_at
  BEFORE UPDATE ON instructors
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_pupils_updated_at
  BEFORE UPDATE ON pupils
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_lessons_updated_at
  BEFORE UPDATE ON lessons
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- PERFORMANCE INDEXES
-- ============================================

-- Profiles
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);

-- Instructor queries
CREATE INDEX IF NOT EXISTS idx_instructors_location ON instructors USING GIST (point(location_lng, location_lat));
CREATE INDEX IF NOT EXISTS idx_instructors_verified ON instructors(is_verified) WHERE is_verified = TRUE;

-- Pupil queries
CREATE INDEX IF NOT EXISTS idx_pupils_instructor ON pupils(instructor_id);
CREATE INDEX IF NOT EXISTS idx_pupils_profile ON pupils(profile_id);
CREATE INDEX IF NOT EXISTS idx_pupils_status ON pupils(status);

-- Instructor-pupil links
CREATE INDEX IF NOT EXISTS idx_links_instructor ON instructor_pupil_links(instructor_id, status);
CREATE INDEX IF NOT EXISTS idx_links_pupil ON instructor_pupil_links(pupil_id);

-- Lesson queries
CREATE INDEX IF NOT EXISTS idx_lessons_instructor_date ON lessons(instructor_id, date);
CREATE INDEX IF NOT EXISTS idx_lessons_pupil_date ON lessons(pupil_id, date);
CREATE INDEX IF NOT EXISTS idx_lessons_status ON lessons(status);

-- Payment queries
CREATE INDEX IF NOT EXISTS idx_payments_instructor ON payments(instructor_id);
CREATE INDEX IF NOT EXISTS idx_payments_pupil ON payments(pupil_id);

-- Message queries
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_receiver ON messages(receiver_id, created_at DESC);

-- Enquiry queries
CREATE INDEX IF NOT EXISTS idx_enquiries_instructor ON enquiries(instructor_id, status);
CREATE INDEX IF NOT EXISTS idx_enquiries_pupil ON enquiries(pupil_id);
CREATE INDEX IF NOT EXISTS idx_enquiries_created ON enquiries(created_at DESC);

-- Open slots
CREATE INDEX IF NOT EXISTS idx_open_slots_instructor ON open_slots(instructor_id, date, is_booked);
CREATE INDEX IF NOT EXISTS idx_open_slots_date ON open_slots(date);

-- Invoice queries
CREATE INDEX IF NOT EXISTS idx_invoices_instructor ON invoices(instructor_id, status);
CREATE INDEX IF NOT EXISTS idx_invoices_pupil ON invoices(pupil_id);

-- Notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user ON app_notifications(user_id, created_at DESC);

-- Teaching resources
CREATE INDEX IF NOT EXISTS idx_resources_instructor ON teaching_resources(instructor_id);

-- Resource pupil access
CREATE INDEX IF NOT EXISTS idx_resource_access_pupil ON resource_pupil_access(pupil_id);
CREATE INDEX IF NOT EXISTS idx_resource_access_resource ON resource_pupil_access(resource_id);

-- Test reports
CREATE INDEX IF NOT EXISTS idx_test_reports_pupil ON test_reports(pupil_id);
CREATE INDEX IF NOT EXISTS idx_test_reports_instructor ON test_reports(instructor_id);

-- Vehicles
CREATE INDEX IF NOT EXISTS idx_vehicles_instructor ON vehicles(instructor_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_primary ON vehicles(instructor_id, is_primary) WHERE is_primary = TRUE;

-- Calendar events
CREATE INDEX IF NOT EXISTS idx_calendar_events_instructor ON calendar_events(instructor_id, start_date);

-- Pupil invitations
CREATE INDEX IF NOT EXISTS idx_pupil_invitations_instructor ON pupil_invitations(instructor_id);
CREATE INDEX IF NOT EXISTS idx_pupil_invitations_code ON pupil_invitations(invitation_code);
CREATE INDEX IF NOT EXISTS idx_pupil_invitations_email ON pupil_invitations(email);

-- Subscriptions
CREATE INDEX IF NOT EXISTS idx_instructor_subscriptions_instructor ON instructor_subscriptions(instructor_id);
CREATE INDEX IF NOT EXISTS idx_instructor_subscriptions_status ON instructor_subscriptions(status);

-- Promo codes
CREATE INDEX IF NOT EXISTS idx_promo_codes_code ON promo_codes(code);

-- Activity logs
CREATE INDEX IF NOT EXISTS idx_activity_logs_instructor ON instructor_activity_logs(instructor_id, created_at DESC);

-- Instructor locations
CREATE INDEX IF NOT EXISTS idx_instructor_locations_instructor ON instructor_locations(instructor_id, timestamp DESC);

-- Support conversations
CREATE INDEX IF NOT EXISTS idx_support_conversations_instructor ON support_conversations(instructor_id);
CREATE INDEX IF NOT EXISTS idx_support_conversations_status ON support_conversations(status);

-- Events
CREATE INDEX IF NOT EXISTS idx_events_active ON events(is_active);
CREATE INDEX IF NOT EXISTS idx_events_dates ON events(start_date, end_date);

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

-- Grant usage on sequences
GRANT USAGE ON SEQUENCE invoice_sequence TO authenticated;

-- Grant table permissions to authenticated role
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Grant anon role permissions for public operations
GRANT SELECT ON banners TO anon;
GRANT SELECT ON subscription_plans TO anon;
GRANT SELECT ON promo_codes TO anon;
GRANT INSERT ON enquiries TO anon;
GRANT SELECT ON pupil_invitations TO anon;
GRANT SELECT ON instructors TO anon;
GRANT SELECT ON profiles TO anon;

-- ============================================
-- SETUP COMPLETE
-- ============================================
