-- Allow pupils to read their instructor's profile.
-- A pupil is linked to an instructor via instructor_pupil_links.

DROP POLICY IF EXISTS "pupils_read_instructor_profile" ON public.profiles;

CREATE POLICY "pupils_read_instructor_profile" ON public.profiles
  FOR SELECT
  TO authenticated
  USING (
    -- Allow if the user is the instructor themselves
    auth.uid() = id
    OR
    -- Allow if this profile belongs to the pupil's instructor
    EXISTS (
      SELECT 1
      FROM public.instructor_pupil_links
      WHERE instructor_id = profiles.id
        AND pupil_id = auth.uid()
        AND status = 'active'
    )
  );
