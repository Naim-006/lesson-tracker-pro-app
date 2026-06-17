-- Supabase Database Updates for Lesson Tracker Pro
-- Run this after the initial database setup to add missing features

-- ============================================
-- NOTIFICATIONS TABLE (for in-app notifications)
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

-- Index for notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user ON app_notifications(user_id, created_at DESC);

-- ============================================
-- BANNERS/PROMOTIONS TABLE
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

-- RLS Policies for banners (public read, admin write)
ALTER TABLE banners ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view active banners"
  ON banners FOR SELECT
  USING (
    is_active = TRUE AND
    (start_date <= NOW() OR start_date IS NULL) AND
    (end_date >= NOW() OR end_date IS NULL)
  );

-- ============================================
-- VEHICLES TABLE (for instructor vehicle management)
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

-- RLS Policies for vehicles
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can manage own vehicles"
  ON vehicles FOR ALL
  USING (auth.uid() = instructor_id);

-- ============================================
-- CALENDAR EVENTS TABLE (for instructor calendar events)
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

-- RLS Policies for calendar_events
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can manage own calendar events"
  ON calendar_events FOR ALL
  USING (auth.uid() = instructor_id);

-- ============================================
-- SETTINGS TABLE (for app settings)
-- ============================================
CREATE TABLE IF NOT EXISTS user_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  key TEXT NOT NULL,
  value JSONB NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, key)
);

-- RLS Policies for user_settings
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own settings"
  ON user_settings FOR ALL
  USING (auth.uid() = user_id);

-- ============================================
-- MISSING FIELDS IN LESSONS TABLE
-- ============================================
-- Add lesson_type field if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'lessons' AND column_name = 'lesson_type'
  ) THEN
    ALTER TABLE lessons ADD COLUMN lesson_type TEXT CHECK (lesson_type IN ('standard', 'motorway', 'pass_plus', 'mock_test', 'refresher'));
  END IF;
END $$;

-- Add dropoff_location field if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'lessons' AND column_name = 'dropoff_location'
  ) THEN
    ALTER TABLE lessons ADD COLUMN dropoff_location TEXT;
  END IF;
END $$;

-- ============================================
-- MISSING FIELDS IN PUPILS TABLE
-- ============================================
-- Add gearbox_preference field if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pupils' AND column_name = 'gearbox_preference'
  ) THEN
    ALTER TABLE pupils ADD COLUMN gearbox_preference TEXT CHECK (gearbox_preference IN ('manual', 'automatic', 'any'));
  END IF;
END $$;

-- Add learning_goals field if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pupils' AND column_name = 'learning_goals'
  ) THEN
    ALTER TABLE pupils ADD COLUMN learning_goals TEXT[];
  END IF;
END $$;

-- Add experience_level field if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pupils' AND column_name = 'experience_level'
  ) THEN
    ALTER TABLE pupils ADD COLUMN experience_level TEXT CHECK (experience_level IN ('beginner', 'intermediate', 'advanced'));
  END IF;
END $$;

-- Add emergency_contact_name field if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pupils' AND column_name = 'emergency_contact_name'
  ) THEN
    ALTER TABLE pupils ADD COLUMN emergency_contact_name TEXT;
  END IF;
END $$;

-- Add emergency_contact_phone field if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pupils' AND column_name = 'emergency_contact_phone'
  ) THEN
    ALTER TABLE pupils ADD COLUMN emergency_contact_phone TEXT;
  END IF;
END $$;

-- Add test_date field if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pupils' AND column_name = 'test_date'
  ) THEN
    ALTER TABLE pupils ADD COLUMN test_date DATE;
  END IF;
END $$;

-- Add preferred_days field if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pupils' AND column_name = 'preferred_days'
  ) THEN
    ALTER TABLE pupils ADD COLUMN preferred_days TEXT[];
  END IF;
END $$;

-- Add preferred_times field if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'pupils' AND column_name = 'preferred_times'
  ) THEN
    ALTER TABLE pupils ADD COLUMN preferred_times TEXT[];
  END IF;
END $$;

-- ============================================
-- SETUP COMPLETE
-- ============================================
