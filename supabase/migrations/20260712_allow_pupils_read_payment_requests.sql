-- Allow pupils to read their own payment requests from instructor.

DROP POLICY IF EXISTS "pupils_read_own_payment_requests" ON public.instructor_payment_requests;

CREATE POLICY "pupils_read_own_payment_requests" ON public.instructor_payment_requests
  FOR SELECT
  TO authenticated
  USING (pupil_id = auth.uid());

-- Allow pupils to update (mark as paid/approved) their own requests
DROP POLICY IF EXISTS "pupils_update_own_payment_requests" ON public.instructor_payment_requests;

CREATE POLICY "pupils_update_own_payment_requests" ON public.instructor_payment_requests
  FOR UPDATE
  TO authenticated
  USING (pupil_id = auth.uid())
  WITH CHECK (pupil_id = auth.uid());
