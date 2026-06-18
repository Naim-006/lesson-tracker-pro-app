-- ============================================
-- PUPIL INVITE SYSTEM MIGRATION
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. Add new columns to pupil_invitations
ALTER TABLE pupil_invitations
  ADD COLUMN IF NOT EXISTS token UUID DEFAULT gen_random_uuid() UNIQUE,
  ADD COLUMN IF NOT EXISTS form_data JSONB DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS form_submitted_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS dropoff_address TEXT,
  ADD COLUMN IF NOT EXISTS hourly_rate DECIMAL(10,2),
  ADD COLUMN IF NOT EXISTS notes TEXT;

-- 2. Update status constraint to include 'rejected'
ALTER TABLE pupil_invitations DROP CONSTRAINT IF EXISTS pupil_invitations_status_check;
ALTER TABLE pupil_invitations ADD CONSTRAINT pupil_invitations_status_check
  CHECK (status IN ('pending', 'submitted', 'approved', 'rejected', 'accepted', 'expired'));

-- 3. Update source constraint
ALTER TABLE pupil_invitations DROP CONSTRAINT IF EXISTS pupil_invitations_source_check;
ALTER TABLE pupil_invitations ADD CONSTRAINT pupil_invitations_source_check
  CHECK (source IN ('manual', 'public_form', 'web_form'));

-- 4. Generate tokens for existing invitations that don't have one
UPDATE pupil_invitations SET token = gen_random_uuid() WHERE token IS NULL;

-- 5. Add index for token lookup (web form uses this)
CREATE INDEX IF NOT EXISTS idx_pupil_invitations_token ON pupil_invitations(token);

-- 6. Add index for status filtering
CREATE INDEX IF NOT EXISTS idx_pupil_invitations_status ON pupil_invitations(status);

-- 7. RLS: Allow public read by token (for web form)
CREATE POLICY "Public can view invitation by token"
  ON pupil_invitations FOR SELECT
  USING (true);

-- 8. RLS: Allow public insert (for web form submissions)
CREATE POLICY "Public can submit invitation form"
  ON pupil_invitations FOR INSERT
  WITH CHECK (true);

-- 9. RLS: Allow public update by token (for form submission)
CREATE POLICY "Public can update invitation by token"
  ON pupil_invitations FOR UPDATE
  USING (true)
  WITH CHECK (true);

-- 10. Create a function to get invitation by token (bypasses RLS for web)
CREATE OR REPLACE FUNCTION get_invitation_by_token(invite_token UUID)
RETURNS TABLE (
  id UUID,
  instructor_id UUID,
  email TEXT,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  postcode TEXT,
  invitation_code TEXT,
  status TEXT,
  source TEXT,
  form_data JSONB,
  form_submitted_at TIMESTAMP WITH TIME ZONE,
  dropoff_address TEXT,
  hourly_rate DECIMAL(10,2),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE,
  approved_at TIMESTAMP WITH TIME ZONE,
  accepted_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id, p.instructor_id, p.email, p.first_name, p.last_name,
    p.phone, p.postcode, p.invitation_code, p.status, p.source,
    p.form_data, p.form_submitted_at, p.dropoff_address,
    p.hourly_rate, p.notes, p.created_at, p.approved_at, p.accepted_at
  FROM pupil_invitations p
  WHERE p.token = invite_token;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11. Create a function to submit form data (bypasses RLS for web)
CREATE OR REPLACE FUNCTION submit_pupil_form(
  invite_token UUID,
  p_first_name TEXT,
  p_last_name TEXT,
  p_email TEXT,
  p_phone TEXT,
  p_postcode TEXT,
  p_dropoff_address TEXT,
  p_form_data JSONB
)
RETURNS JSONB AS $$
DECLARE
  invitation_record RECORD;
  result JSONB;
BEGIN
  -- Find the invitation
  SELECT * INTO invitation_record
  FROM pupil_invitations
  WHERE token = invite_token;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid invitation link');
  END IF;

  -- Check if already submitted
  IF invitation_record.status = 'submitted' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Form already submitted');
  END IF;

  IF invitation_record.status = 'approved' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invitation already approved');
  END IF;

  IF invitation_record.status = 'rejected' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invitation was rejected');
  END IF;

  IF invitation_record.status = 'accepted' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invitation already accepted');
  END IF;

  -- Update the invitation with form data
  UPDATE pupil_invitations
  SET
    first_name = COALESCE(p_first_name, first_name),
    last_name = COALESCE(p_last_name, last_name),
    email = COALESCE(p_email, email),
    phone = COALESCE(p_phone, phone),
    postcode = COALESCE(p_postcode, postcode),
    dropoff_address = p_dropoff_address,
    form_data = p_form_data,
    form_submitted_at = NOW(),
    status = 'submitted',
    source = 'web_form'
  WHERE token = invite_token;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Form submitted successfully. Waiting for instructor approval.',
    'invitation_id', invitation_record.id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 12. Create a function to approve invitation (instructor action)
CREATE OR REPLACE FUNCTION approve_pupil_invitation(
  invite_id UUID,
  p_hourly_rate DECIMAL(10,2) DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  invitation_record RECORD;
BEGIN
  SELECT * INTO invitation_record
  FROM pupil_invitations
  WHERE id = invite_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invitation not found');
  END IF;

  IF invitation_record.status != 'submitted' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invitation is not in submitted state');
  END IF;

  UPDATE pupil_invitations
  SET
    status = 'approved',
    approved_at = NOW(),
    hourly_rate = COALESCE(p_hourly_rate, hourly_rate),
    notes = COALESCE(p_notes, notes)
  WHERE id = invite_id;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Invitation approved. Pupil can now sign up.',
    'invitation_id', invite_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 13. Create a function to reject invitation (instructor action)
CREATE OR REPLACE FUNCTION reject_pupil_invitation(
  invite_id UUID,
  p_notes TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
BEGIN
  UPDATE pupil_invitations
  SET
    status = 'rejected',
    notes = COALESCE(p_notes, notes)
  WHERE id = invite_id;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Invitation rejected.',
    'invitation_id', invite_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 14. Create a function to get instructor's invitation stats
CREATE OR REPLACE FUNCTION get_invitation_stats(p_instructor_id UUID)
RETURNS JSONB AS $$
DECLARE
  stats JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total', COUNT(*),
    'pending', COUNT(*) FILTER (WHERE status = 'pending'),
    'submitted', COUNT(*) FILTER (WHERE status = 'submitted'),
    'approved', COUNT(*) FILTER (WHERE status = 'approved'),
    'rejected', COUNT(*) FILTER (WHERE status = 'rejected'),
    'accepted', COUNT(*) FILTER (WHERE status = 'accepted')
  ) INTO stats
  FROM pupil_invitations
  WHERE instructor_id = p_instructor_id;

  RETURN stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Done!
SELECT 'Pupil invite system migration complete!' as result;
