-- Supabase Database Setup for Lesson Tracker Pro
-- Run this entire script in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- CORE TABLES (Create all tables first without RLS)
-- ============================================

-- 1. profiles (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS profiles (
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

-- 3. pupils (Pupil-specific data)
CREATE TABLE IF NOT EXISTS pupils (
  id UUID REFERENCES profiles(id) PRIMARY KEY,
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
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. instructor_pupil_links (Many-to-many relationship)
CREATE TABLE IF NOT EXISTS instructor_pupil_links (
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

-- 6. payments (Financial transactions)
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

-- 7. enquiries (Pupil enquiries to instructors)
CREATE TABLE IF NOT EXISTS enquiries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pupil_id UUID REFERENCES pupils(id) ON DELETE CASCADE,
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  status TEXT CHECK (status IN ('pending', 'responded', 'accepted', 'rejected')) DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. messages (In-app messaging)
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  receiver_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  lesson_id UUID REFERENCES lessons(id) ON DELETE SET NULL,
  content TEXT NOT NULL,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. open_slots (Instructor available slots)
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

-- 10. progress_categories (Skill categories)
CREATE TABLE IF NOT EXISTS progress_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 11. progress_skills (Individual skills within categories)
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

-- 12. teaching_resources (Instructor teaching materials)
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

-- 13. resource_pupil_access (Selective resource access)
CREATE TABLE IF NOT EXISTS resource_pupil_access (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resource_id UUID REFERENCES teaching_resources(id) ON DELETE CASCADE,
  pupil_id UUID REFERENCES pupils(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(resource_id, pupil_id)
);

-- 14. test_reports (Driving test reports)
CREATE TABLE IF NOT EXISTS test_reports (
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

-- 16. mileage_entries (Vehicle mileage tracking)
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
-- ROW LEVEL SECURITY POLICIES (Add after all tables exist)
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
    INSERT INTO public.pupils (id)
    VALUES (NEW.id);
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
BEGIN
  -- Generate invoice number in format: INV-YYYYMMDD-XXXX
  invoice_num := 'INV-' || TO_CHAR(NEW.created_at, 'YYYYMMDD') || '-' || LPAD((ROW_NUMBER() OVER (ORDER BY NEW.created_at))::TEXT, 4, '0');
  NEW.invoice_number := invoice_num;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_invoice_created ON invoices;
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

-- ============================================
-- SETUP COMPLETE
-- ============================================
