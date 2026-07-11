-- Allow pupils to read their instructor's vehicles.
-- A pupil is linked to an instructor via instructor_pupil_links.

DROP POLICY IF EXISTS "pupils_read_instructor_vehicles" ON public.vehicles;

CREATE POLICY "pupils_read_instructor_vehicles" ON public.vehicles
  FOR SELECT
  TO authenticated
  USING (
    instructor_id IN (
      SELECT instructor_id
      FROM public.instructor_pupil_links
      WHERE pupil_id = auth.uid()
        AND status = 'active'
    )
  );
