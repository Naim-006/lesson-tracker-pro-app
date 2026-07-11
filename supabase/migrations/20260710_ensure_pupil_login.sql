-- RPC to ensure a pupil record exists for the auth user after login
-- SECURITY DEFINER bypasses RLS so the pupil can migrate their own record
CREATE OR REPLACE FUNCTION public.ensure_pupil_login(p_email TEXT, p_auth_id UUID)
RETURNS JSON
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
DECLARE
  v_pupil RECORD;
  v_invitation RECORD;
  v_submission RECORD;
  v_instructor_id UUID;
BEGIN
  -- 1. Check if pupil already exists for this auth ID
  SELECT * INTO v_pupil FROM pupils WHERE id = p_auth_id;
  IF FOUND THEN
    IF v_pupil.status = 'current' THEN
      RETURN json_build_object('status', 'active');
    ELSE
      RETURN json_build_object('status', 'revoked');
    END IF;
  END IF;

  -- 2. Try to find by email and migrate the ID
  SELECT * INTO v_pupil FROM pupils WHERE email = p_email LIMIT 1;
  IF FOUND THEN
    v_instructor_id := v_pupil.instructor_id;
    DELETE FROM instructor_pupil_links WHERE pupil_id = v_pupil.id;
    DELETE FROM pupils WHERE id = v_pupil.id;
    INSERT INTO pupils (id, instructor_id, email, first_name, last_name, phone, postcode, status, created_at)
    VALUES (p_auth_id, v_instructor_id, v_pupil.email, v_pupil.first_name, v_pupil.last_name, v_pupil.phone, v_pupil.postcode, 'current', v_pupil.created_at);
    INSERT INTO instructor_pupil_links (instructor_id, pupil_id, status)
    VALUES (v_instructor_id, p_auth_id, 'active');
    RETURN json_build_object('status', 'active');
  END IF;

  -- 3. Try invitation (any status)
  SELECT * INTO v_invitation FROM pupil_invitations WHERE email = p_email LIMIT 1;
  IF FOUND THEN
    INSERT INTO pupils (id, instructor_id, email, first_name, last_name, phone, postcode, status, created_at)
    VALUES (p_auth_id, v_invitation.instructor_id, p_email, v_invitation.first_name, v_invitation.last_name, v_invitation.phone, v_invitation.postcode, 'current', NOW());
    INSERT INTO instructor_pupil_links (instructor_id, pupil_id, status)
    VALUES (v_invitation.instructor_id, p_auth_id, 'active');
    RETURN json_build_object('status', 'active');
  END IF;

  -- 4. Try submission (any status)
  SELECT * INTO v_submission FROM pupil_invite_submissions WHERE email = p_email LIMIT 1;
  IF FOUND THEN
    INSERT INTO pupils (id, instructor_id, email, first_name, last_name, phone, postcode, status, created_at)
    VALUES (p_auth_id, v_submission.instructor_id, p_email, v_submission.first_name, v_submission.last_name, v_submission.phone, v_submission.postcode, 'current', NOW());
    INSERT INTO instructor_pupil_links (instructor_id, pupil_id, status)
    VALUES (v_submission.instructor_id, p_auth_id, 'active');
    RETURN json_build_object('status', 'active');
  END IF;

  -- 5. Nothing found at all
  RETURN json_build_object('status', 'not_found');
END;
$$;
