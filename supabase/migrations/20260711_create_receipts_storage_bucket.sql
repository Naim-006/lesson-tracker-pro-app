-- Supabase Storage bucket for transaction receipt images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'receipts',
  'receipts',
  false,
  10485760,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- Instructors can upload receipts to their own folder
DROP POLICY IF EXISTS "instructors_upload_receipts" ON storage.objects;
CREATE POLICY "instructors_upload_receipts" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'receipts'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Instructors can read their own receipts
DROP POLICY IF EXISTS "instructors_read_receipts" ON storage.objects;
CREATE POLICY "instructors_read_receipts" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'receipts'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Instructors can update/replace their own receipts
DROP POLICY IF EXISTS "instructors_update_receipts" ON storage.objects;
CREATE POLICY "instructors_update_receipts" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'receipts'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Instructors can delete their own receipts
DROP POLICY IF EXISTS "instructors_delete_receipts" ON storage.objects;
CREATE POLICY "instructors_delete_receipts" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'receipts'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
