-- Create invite links for instructors who signed up before the trigger was added
INSERT INTO public.pupil_invite_links (instructor_id, token, is_active)
SELECT
  p.id,
  encode(gen_random_bytes(12), 'hex'),
  true
FROM public.profiles p
WHERE p.role = 'instructor'
  AND NOT EXISTS (
    SELECT 1 FROM public.pupil_invite_links l WHERE l.instructor_id = p.id
  );
