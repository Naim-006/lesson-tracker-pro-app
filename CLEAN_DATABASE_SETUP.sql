-- Supabase Database Setup for Lesson Tracker Pro - CLEAN VERSION
-- Run this entire script in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- DROP EXISTING OBJECTS (to avoid duplicate errors)
-- ============================================

-- Drop all triggers first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_email_confirmed ON auth.users;
DROP TRIGGER IF EXISTS on_invoice_created ON invoices;

-- Drop all functions
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS public.update_email_verification();
DROP FUNCTION IF EXISTS public.generate_invoice_number();

-- Drop all policies (order matters - dependencies)
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Instructors can view linked pupils" ON profiles;

DROP POLICY IF EXISTS "Instructors can view own data" ON instructors;
DROP POLICY IF EXISTS "Pupils can view linked instructors" ON instructors;
DROP POLICY IF EXISTS "Public can view verified instructors for discovery" ON instructors;

DROP POLICY IF EXISTS "Pupils can view own data" ON pupils;
DROP POLICY IF EXISTS "Instructors can view linked pupils" ON pupils;

DROP POLICY IF EXISTS "Instructors can view own links" ON instructor_pupil_links;
DROP POLICY IF EXISTS "Pupils can view own links" ON instructor_pupil_links;

DROP POLICY IF EXISTS "Instructors can view own lessons" ON lessons;
DROP POLICY IF EXISTS "Pupils can view own lessons" ON lessons;

DROP POLICY IF EXISTS "Instructors can view own payments" ON payments;
DROP POLICY IF EXISTS "Pupils can view own payments" ON payments;

DROP POLICY IF EXISTS "Instructors can view enquiries sent to them" ON enquiries;
DROP POLICY IF EXISTS "Pupils can view own enquiries" ON enquiries;

DROP POLICY IF EXISTS "Users can view messages they sent or received" ON messages;
DROP POLICY IF EXISTS "Users can insert messages they send" ON messages;
DROP POLICY IF EXISTS "Users can update messages they sent" ON messages;

DROP POLICY IF EXISTS "Instructors can manage own slots" ON open_slots;
DROP POLICY IF EXISTS "Pupils can view available slots" ON open_slots;

DROP POLICY IF EXISTS "Instructors can manage own categories" ON progress_categories;
DROP POLICY IF EXISTS "Pupils can view linked instructor categories" ON progress_categories;

DROP POLICY IF EXISTS "Instructors can view linked pupil skills" ON progress_skills;
DROP POLICY IF EXISTS "Pupils can view own skills" ON progress_skills;

DROP POLICY IF EXISTS "Instructors can manage own resources" ON teaching_resources;
DROP POLICY IF EXISTS "Pupils can view linked instructor public resources" ON teaching_resources;

DROP POLICY IF EXISTS "Instructors can manage resource access" ON resource_pupil_access;
DROP POLICY IF EXISTS "Pupils can view their resource access" ON resource_pupil_access;

DROP POLICY IF EXISTS "Instructors can view linked pupil reports" ON test_reports;
DROP POLICY IF EXISTS "Pupils can view own reports" ON test_reports;

DROP POLICY IF EXISTS "Instructors can manage own invoices" ON invoices;
DROP POLICY IF EXISTS "Pupils can view own invoices" ON invoices;

DROP POLICY IF EXISTS "Instructors can manage own mileage" ON mileage_entries;

DROP POLICY IF EXISTS "Instructors can manage own invitations" ON pupil_invitations;
DROP POLICY IF EXISTS "Public can view active invitations" ON pupil_invitations;

DROP POLICY IF EXISTS "Users can view own notifications" ON app_notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON app_notifications;
DROP POLICY IF EXISTS "Users can insert own notifications" ON app_notifications;
DROP POLICY IF EXISTS "Users can delete own notifications" ON app_notifications;

DROP POLICY IF EXISTS "Public can view active banners" ON banners;

DROP POLICY IF EXISTS "Instructors can manage own vehicles" ON vehicles;

DROP POLICY IF EXISTS "Instructors can manage own calendar events" ON calendar_events;

DROP POLICY IF EXISTS "Users can manage own settings" ON user_settings;

-- Drop all tables (order matters - dependencies)
DROP TABLE IF EXISTS pupil_invitations;
DROP TABLE IF EXISTS app_notifications;
DROP TABLE IF EXISTS banners;
DROP TABLE IF EXISTS vehicles;
DROP TABLE IF EXISTS calendar_events;
DROP TABLE IF EXISTS user_settings;
DROP TABLE IF EXISTS mileage_entries;
DROP TABLE IF EXISTS invoices;
DROP TABLE IF EXISTS test_reports;
DROP TABLE IF EXISTS resource_pupil_access;
DROP TABLE IF EXISTS teaching_resources;
DROP TABLE IF EXISTS progress_skills;
DROP TABLE IF EXISTS progress_categories;
DROP TABLE IF EXISTS open_slots;
DROP TABLE IF EXISTS messages;
DROP TABLE IF EXISTS enquiries;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS lessons;
DROP TABLE IF EXISTS instructor_pupil_links;
DROP TABLE IF EXISTS pupils;
DROP TABLE IF EXISTS instructors;
DROP TABLE IF EXISTS profiles;

-- ============================================
-- CORE TABLES (Create all tables first without RLS)
-- ============================================

-- 1. profiles (extends Supabase auth.users)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  phone TEXT,
  role TEXT NOT NULL CHECK (role IN ('instructor', 'pupil')),
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  email_verified BOOLEAN DEFAULT FALSE
);

-- 2. instructors (Instructor-specific data)
CREATE TABLE instructors (
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

-- 3. pupils (Pupil-specific data) - FIXED SCHEMA
CREATE TABLE pupils (
  id UUID REFERENCES profiles(id) PRIMARY KEY,
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  address TEXT,
  postcode TEXT,
  status TEXT CHECK (status IN ('current', 'former', 'prospective')) DEFAULT 'current',
  gearbox_preference TEXT CHECK (gearbox_preference IN ('manual', 'automatic', 'any')),
  learning_goals TEXT[],
  experience_level TEXT CHECK (experience_level IN ('beginner', 'intermediate', 'advanced')),
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  test_date DATE,
  preferred_days TEXT[],
  preferred_times TEXT[],
  test_progress JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. instructor_pupil_links (Many-to-many relationship)
CREATE TABLE instructor_pupil_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  pupil_id UUID REFERENCES pupils(id) ON DELETE CASCADE,
  status TEXT CHECK (status IN ('pending', 'active', 'inactive', 'completed')) DEFAULT 'pending',
  hourly_rate DECIMAL(10,2),
  linked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(instructor_id, pupil_id)
);

-- 5. lessons (Lesson bookings)
CREATE TABLE lessons (
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

-- 6. payments (Financial transactions)
CREATE TABLE payments (
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

-- 7. enquiries (Pupil enquiries to instructors)
CREATE TABLE enquiries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pupil_id UUID REFERENCES pupils(id) ON DELETE CASCADE,
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  status TEXT CHECK (status IN ('pending', 'responded', 'accepted', 'rejected')) DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. messages (In-app messaging)
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  receiver_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  lesson_id UUID REFERENCES lessons(id) ON DELETE SET NULL,
  content TEXT NOT NULL,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. open_slots (Instructor available slots)
CREATE TABLE open_slots (
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

-- 10. progress_categories (Skill categories)
CREATE TABLE progress_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 11. progress_skills (Individual skills within categories)
CREATE TABLE progress_skills (
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

-- 12. teaching_resources (Instructor teaching materials)
CREATE TABLE teaching_resources (
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

-- 13. resource_pupil_access (Selective resource access)
CREATE TABLE resource_pupil_access (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resource_id UUID REFERENCES teaching_resources(id) ON DELETE CASCADE,
  pupil_id UUID REFERENCES pupils(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(resource_id, pupil_id)
);

-- 14. test_reports (Driving test reports)
CREATE TABLE test_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pupil_id UUID REFERENCES pupils(id) ON DELETE CASCADE,
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  test_date DATE NOT NULL,
  test_center_name TEXT,
  test_center_id INTEGER,
  result TEXT CHECK (result IN ('pass', 'fail')) NOT NULL,
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

-- 15. invoices (Payment requests from instructors)
CREATE TABLE invoices (
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

-- 16. mileage_entries (Vehicle mileage tracking)
CREATE TABLE mileage_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  miles DECIMAL(10,2) NOT NULL,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 17. pupil_invitations (NEW - for pupil invitations and whitelisting)
CREATE TABLE pupil_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  postcode TEXT,
  invitation_code TEXT UNIQUE NOT NULL,
  status TEXT CHECK (status IN ('pending', 'accepted', 'approved', 'expired')) DEFAULT 'pending',
  source TEXT CHECK (source IN ('manual', 'public_form')) DEFAULT 'manual',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  accepted_at TIMESTAMP WITH TIME ZONE,
  approved_at TIMESTAMP WITH TIME ZONE
);

-- 18. app_notifications (for in-app notifications)
CREATE TABLE app_notifications (
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

-- 19. banners (promotions/announcements)
CREATE TABLE banners (
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

-- 20. vehicles (instructor vehicle management)
CREATE TABLE vehicles (
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

-- 21. calendar_events (instructor calendar events)
CREATE TABLE calendar_events (
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

-- 22. user_settings (app settings)
CREATE TABLE user_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  key TEXT NOT NULL,
  value JSONB NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, key)
);

-- ============================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================

-- RLS Policies for profiles
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

-- RLS Policies for instructors
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

-- RLS Policies for pupils
ALTER TABLE pupils ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Pupils can view own data"
  ON pupils FOR ALL
  USING (auth.uid() = id);

CREATE POLICY "Instructors can view linked pupils"
  ON pupils FOR SELECT
  USING (
    auth.uid() IN (
      SELECT instructor_id FROM instructor_pupil_links WHERE pupil_id = pupils.id
    )
  );

-- RLS Policies for instructor_pupil_links
ALTER TABLE instructor_pupil_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can view own links"
  ON instructor_pupil_links FOR ALL
  USING (auth.uid() = instructor_id);

CREATE POLICY "Pupils can view own links"
  ON instructor_pupil_links FOR ALL
  USING (auth.uid() = pupil_id);

-- RLS Policies for lessons
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can view own lessons"
  ON lessons FOR ALL
  USING (auth.uid() = instructor_id);

CREATE POLICY "Pupils can view own lessons"
  ON lessons FOR ALL
  USING (auth.uid() = pupil_id);

-- RLS Policies for payments
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can view own payments"
  ON payments FOR ALL
  USING (auth.uid() = instructor_id);

CREATE POLICY "Pupils can view own payments"
  ON payments FOR SELECT
  USING (auth.uid() = pupil_id);

-- RLS Policies for enquiries
ALTER TABLE enquiries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can view enquiries sent to them"
  ON enquiries FOR ALL
  USING (auth.uid() = instructor_id);

CREATE POLICY "Pupils can view own enquiries"
  ON enquiries FOR ALL
  USING (auth.uid() = pupil_id);

-- RLS Policies for messages
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

-- RLS Policies for open_slots
ALTER TABLE open_slots ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can manage own slots"
  ON open_slots FOR ALL
  USING (auth.uid() = instructor_id);

CREATE POLICY "Pupils can view available slots"
  ON open_slots FOR SELECT
  USING (is_booked = FALSE);

-- RLS Policies for progress_categories
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

-- RLS Policies for progress_skills
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

-- RLS Policies for teaching_resources
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

-- RLS Policies for resource_pupil_access
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

-- RLS Policies for test_reports
ALTER TABLE test_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can view linked pupil reports"
  ON test_reports FOR ALL
  USING (auth.uid() = instructor_id);

CREATE POLICY "Pupils can view own reports"
  ON test_reports FOR SELECT
  USING (auth.uid() = pupil_id);

-- RLS Policies for invoices
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can manage own invoices"
  ON invoices FOR ALL
  USING (auth.uid() = instructor_id);

CREATE POLICY "Pupils can view own invoices"
  ON invoices FOR SELECT
  USING (auth.uid() = pupil_id);

-- RLS Policies for mileage_entries
ALTER TABLE mileage_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can manage own mileage"
  ON mileage_entries FOR ALL
  USING (auth.uid() = instructor_id);

-- RLS Policies for pupil_invitations
ALTER TABLE pupil_invitations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can manage own invitations"
  ON pupil_invitations FOR ALL
  USING (auth.uid() = instructor_id);

CREATE POLICY "Public can view active invitations"
  ON pupil_invitations FOR SELECT
  USING (status = 'pending');

-- RLS Policies for app_notifications
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

-- RLS Policies for banners
ALTER TABLE banners ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view active banners"
  ON banners FOR SELECT
  USING (
    is_active = TRUE AND
    (start_date <= NOW() OR start_date IS NULL) AND
    (end_date >= NOW() OR end_date IS NULL)
  );

-- RLS Policies for vehicles
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can manage own vehicles"
  ON vehicles FOR ALL
  USING (auth.uid() = instructor_id);

-- RLS Policies for calendar_events
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can manage own calendar events"
  ON calendar_events FOR ALL
  USING (auth.uid() = instructor_id);

-- RLS Policies for user_settings
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own settings"
  ON user_settings FOR ALL
  USING (auth.uid() = user_id);

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
    INSERT INTO public.pupils (id, email)
    VALUES (NEW.id, NEW.email);
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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

CREATE TRIGGER on_email_confirmed
  AFTER UPDATE OF email_confirmed_at ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.update_email_verification();

-- Function: Auto-generate invoice number
CREATE OR REPLACE FUNCTION public.generate_invoice_number()
RETURNS TRIGGER AS $$
DECLARE
  invoice_num TEXT;
BEGIN
  -- Generate invoice number in format: INV-YYYYMMDD-XXXX
  invoice_num := 'INV-' || TO_CHAR(NEW.created_at, 'YYYYMMDD') || '-' || LPAD((ROW_NUMBER() OVER (ORDER BY NEW.created_at))::TEXT, 4, '0');
  NEW.invoice_number := invoice_num;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_invoice_created
  BEFORE INSERT ON invoices
  FOR EACH ROW EXECUTE FUNCTION public.generate_invoice_number();

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- Instructor queries
CREATE INDEX IF NOT EXISTS idx_instructors_location ON instructors USING GIST (point(location_lng, location_lat));
CREATE INDEX IF NOT EXISTS idx_instructors_verified ON instructors(is_verified) WHERE is_verified = TRUE;

-- Lesson queries
CREATE INDEX IF NOT EXISTS idx_lessons_instructor_date ON lessons(instructor_id, date);
CREATE INDEX IF NOT EXISTS idx_lessons_pupil_date ON lessons(pupil_id, date);

-- Payment queries
CREATE INDEX IF NOT EXISTS idx_payments_instructor ON payments(instructor_id);
CREATE INDEX IF NOT EXISTS idx_payments_pupil ON payments(pupil_id);

-- Message queries
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_receiver ON messages(receiver_id, created_at DESC);

-- Enquiry queries
CREATE INDEX IF NOT EXISTS idx_enquiries_instructor ON enquiries(instructor_id, status);
CREATE INDEX IF NOT EXISTS idx_enquiries_pupil ON enquiries(pupil_id);

-- Open slots
CREATE INDEX IF NOT EXISTS idx_open_slots_instructor ON open_slots(instructor_id, date, is_booked);

-- Invoice queries
CREATE INDEX IF NOT EXISTS idx_invoices_instructor ON invoices(instructor_id, status);
CREATE INDEX IF NOT EXISTS idx_invoices_pupil ON invoices(pupil_id);

-- Pupil invitations
CREATE INDEX IF NOT EXISTS idx_pupil_invitations_instructor ON pupil_invitations(instructor_id, status);
CREATE INDEX IF NOT EXISTS idx_pupil_invitations_code ON pupil_invitations(invitation_code);
CREATE INDEX IF NOT EXISTS idx_pupil_invitations_email ON pupil_invitations(email);

-- Notification queries
CREATE INDEX IF NOT EXISTS idx_notifications_user ON app_notifications(user_id, created_at DESC);

-- ============================================
-- SETUP COMPLETE
-- ============================================

-- Note: This script drops all existing tables and policies first,
-- then recreates them. This ensures a clean setup without duplicate policy errors.
