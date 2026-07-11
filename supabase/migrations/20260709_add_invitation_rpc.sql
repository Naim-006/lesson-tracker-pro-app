-- RPC to look up pupil invitation by email (used during unauthenticated signup)
-- SECURITY DEFINER bypasses RLS so unauthenticated users can check their invitation
CREATE OR REPLACE FUNCTION public.get_pupil_invitation(p_email TEXT)
RETURNS TABLE(id UUID, instructor_id UUID, first_name TEXT, last_name TEXT, phone TEXT, postcode TEXT)
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT pi.id, pi.instructor_id, pi.first_name, pi.last_name, pi.phone, pi.postcode
  FROM public.pupil_invitations pi
  WHERE pi.email = p_email
    AND (pi.status = 'pending' OR pi.status = 'approved');
END;
$$;
