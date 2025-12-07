-- 1. Create (or Update) the Secure Admin Function
-- We set search_path to public to prevent hijacking
-- We set OWNER to postgres (orphaning potential bad owners)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.users
    WHERE id = auth.uid()
    AND role = 'admin'
  );
$$;

ALTER FUNCTION public.is_admin() OWNER TO postgres;
GRANT EXECUTE ON FUNCTION public.is_admin TO authenticated;

-- 2. NUCLEAR OPTION: Drop ALL potential conflicting policies on 'storage.objects'
-- We try every common name to ensure no "Recursive" policy is left behind.
DROP POLICY IF EXISTS "Allow authenticated uploads" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated select" ON storage.objects;
DROP POLICY IF EXISTS "Allow owner or admin select" ON storage.objects;
DROP POLICY IF EXISTS "Give admin access" ON storage.objects;
DROP POLICY IF EXISTS "Admin Select" ON storage.objects;
DROP POLICY IF EXISTS "Enable read access for all users" ON storage.objects;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own files" ON storage.objects;

-- 3. Re-create Upload Policy (Targeting specific bucket)
CREATE POLICY "Allow authenticated uploads"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'kyc_docs' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 4. Re-create View Policy (Owner OR Admin)
-- Uses the SECURE function to avoid recursion
CREATE POLICY "Allow owner or admin select"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'kyc_docs' AND
  (
    (storage.foldername(name))[1] = auth.uid()::text
    OR
    public.is_admin()
  )
);
