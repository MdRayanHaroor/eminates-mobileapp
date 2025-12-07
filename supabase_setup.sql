-- 1. FIX STORAGE PERMISSIONS
-- This policy allows authenticated users to upload files to their own folder in 'kyc_docs'
-- Replace 'kyc_docs' with your actual bucket name if different.

-- Allow uploading (INSERT)
CREATE POLICY "Allow authenticated uploads"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'kyc_docs' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow viewing (SELECT) - needed for the app to verify upload success or show preview
CREATE POLICY "Allow authenticated select"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'kyc_docs' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 2. UPDATE DATABASE TABLE
-- Run this to add the missing columns to your table.
ALTER TABLE investor_requests 
ADD COLUMN pan_card_url text,
ADD COLUMN aadhaar_card_url text,
ADD COLUMN selfie_url text;
