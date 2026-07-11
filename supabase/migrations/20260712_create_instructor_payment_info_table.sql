-- Create instructor_payment_info table if not exists (was missing from main schema)
CREATE TABLE IF NOT EXISTS public.instructor_payment_info (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  methods         JSONB DEFAULT '{}',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(instructor_id)
);

ALTER TABLE public.instructor_payment_info ENABLE ROW LEVEL SECURITY;

-- Instructors can manage their own payment info
DROP POLICY IF EXISTS "instructors_manage_own_payment_info" ON public.instructor_payment_info;
CREATE POLICY "instructors_manage_own_payment_info" ON public.instructor_payment_info
  FOR ALL
  TO authenticated
  USING (instructor_id = auth.uid())
  WITH CHECK (instructor_id = auth.uid());

-- Pupils can read their instructor's payment info
DROP POLICY IF EXISTS "pupils_read_instructor_payment_info" ON public.instructor_payment_info;
CREATE POLICY "pupils_read_instructor_payment_info" ON public.instructor_payment_info
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.instructor_pupil_links
      WHERE instructor_id = instructor_payment_info.instructor_id
        AND pupil_id = auth.uid()
        AND status = 'active'
    )
  );