-- Allow instructors to insert their own payments
DROP POLICY IF EXISTS "instructors_insert_own_payments" ON instructor_payments;
CREATE POLICY "instructors_insert_own_payments" ON instructor_payments
  FOR INSERT WITH CHECK (instructor_id = auth.uid());
