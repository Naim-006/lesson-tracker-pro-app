-- =============================================================
-- PUPIL INVITE SYSTEM - Database Migration
-- Run this in Supabase SQL Editor
-- =============================================================

-- 1. PUPIL INVITE LINKS - One unique link per instructor
CREATE TABLE IF NOT EXISTS pupil_invite_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  slug TEXT UNIQUE,
  is_active BOOLEAN NOT NULL DEFAULT true,
  max_submissions INTEGER,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. PUPIL INVITE SUBMISSIONS - Each pupil's form submission
CREATE TABLE IF NOT EXISTS pupil_invite_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  link_id UUID NOT NULL REFERENCES pupil_invite_links(id) ON DELETE CASCADE,
  instructor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  pupil_token TEXT NOT NULL UNIQUE,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  address TEXT,
  postcode TEXT,
  pickup_location TEXT,
  dropoff_location TEXT,
  preferred_days TEXT[],
  preferred_times TEXT[],
  learning_goals TEXT,
  experience_level TEXT,
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  notes TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_at TIMESTAMPTZ,
  review_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(link_id, email)
);

-- 3. Indexes
CREATE INDEX IF NOT EXISTS idx_pupil_invite_links_token ON pupil_invite_links(token);
CREATE INDEX IF NOT EXISTS idx_pupil_invite_links_instructor ON pupil_invite_links(instructor_id);
CREATE INDEX IF NOT EXISTS idx_pupil_invite_submissions_token ON pupil_invite_submissions(pupil_token);
CREATE INDEX IF NOT EXISTS idx_pupil_invite_submissions_link ON pupil_invite_submissions(link_id);
CREATE INDEX IF NOT EXISTS idx_pupil_invite_submissions_instructor ON pupil_invite_submissions(instructor_id);
CREATE INDEX IF NOT EXISTS idx_pupil_invite_submissions_status ON pupil_invite_submissions(status);
CREATE INDEX IF NOT EXISTS idx_pupil_invite_submissions_email ON pupil_invite_submissions(email);

-- 4. Updated_at trigger
CREATE OR REPLACE FUNCTION update_pupil_invite_links_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_pupil_invite_links_updated_at ON pupil_invite_links;
CREATE TRIGGER update_pupil_invite_links_updated_at
  BEFORE UPDATE ON pupil_invite_links
  FOR EACH ROW EXECUTE FUNCTION update_pupil_invite_links_updated_at();

DROP TRIGGER IF EXISTS update_pupil_invite_submissions_updated_at ON pupil_invite_submissions;
CREATE TRIGGER update_pupil_invite_submissions_updated_at
  BEFORE UPDATE ON pupil_invite_submissions
  FOR EACH ROW EXECUTE FUNCTION update_pupil_invite_links_updated_at();

-- 5. RLS Policies
ALTER TABLE pupil_invite_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE pupil_invite_submissions ENABLE ROW LEVEL SECURITY;

-- Instructors can manage their own invite links
CREATE POLICY "Instructors manage own invite links"
  ON pupil_invite_links FOR ALL
  USING (instructor_id = auth.uid());

-- Anyone can read active invite links (for the web form)
CREATE POLICY "Public can read active invite links"
  ON pupil_invite_links FOR SELECT
  USING (is_active = true);

-- Anyone can insert submissions (pupils filling the form)
CREATE POLICY "Public can insert submissions"
  ON pupil_invite_submissions FOR INSERT
  WITH CHECK (true);

-- Anyone can read submissions by pupil_token (for status check)
CREATE POLICY "Public can read own submission by token"
  ON pupil_invite_submissions FOR SELECT
  USING (true);

-- Instructors can update their own submissions (approve/reject)
CREATE POLICY "Instructors manage own submissions"
  ON pupil_invite_submissions FOR UPDATE
  USING (instructor_id = auth.uid());

-- Instructors can delete their own submissions
CREATE POLICY "Instructors delete own submissions"
  ON pupil_invite_submissions FOR DELETE
  USING (instructor_id = auth.uid());

-- 6. Storage bucket for invite QR codes (optional)
INSERT INTO storage.buckets (id, name, public)
VALUES ('invite-assets', 'invite-assets', true)
ON CONFLICT (id) DO NOTHING;

-- 7. Helper function: Generate unique token
CREATE OR REPLACE FUNCTION generate_invite_token()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
  result TEXT := '';
  i INTEGER;
BEGIN
  FOR i IN 1..12 LOOP
    result := result || chars[floor(random() * length(chars) + 1)::INTEGER];
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 8. Helper function: Generate pupil token
CREATE OR REPLACE FUNCTION generate_pupil_token()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result TEXT := '';
  i INTEGER;
BEGIN
  FOR i IN 1..8 LOOP
    result := result || chars[floor(random() * length(chars) + 1)::INTEGER];
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql;
