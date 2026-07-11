-- Add pupil_id and lesson_ids columns to instructor_payment_requests.
-- These are needed for pupil-facing payment request features.

ALTER TABLE public.instructor_payment_requests
  ADD COLUMN IF NOT EXISTS pupil_id UUID REFERENCES public.pupils(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS lesson_ids JSONB DEFAULT '[]';

CREATE INDEX IF NOT EXISTS idx_payment_requests_pupil ON public.instructor_payment_requests(pupil_id);

-- Allow pupils to read their own payment requests
DROP POLICY IF EXISTS "pupils_read_own_payment_requests" ON public.instructor_payment_requests;
CREATE POLICY "pupils_read_own_payment_requests" ON public.instructor_payment_requests
  FOR SELECT
  TO authenticated
  USING (pupil_id = auth.uid());

-- Allow pupils to update (mark as paid) their own payment requests
DROP POLICY IF EXISTS "pupils_update_own_payment_requests" ON public.instructor_payment_requests;
CREATE POLICY "pupils_update_own_payment_requests" ON public.instructor_payment_requests
  FOR UPDATE
  TO authenticated
  USING (pupil_id = auth.uid())
  WITH CHECK (pupil_id = auth.uid());
