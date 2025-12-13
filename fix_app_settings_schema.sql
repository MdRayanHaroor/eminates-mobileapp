-- Ensuring app_settings has all required columns
ALTER TABLE public.app_settings 
ADD COLUMN IF NOT EXISTS description text,
ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true;

-- Ensure RLS is enabled (idempotent)
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- Re-apply policy just in case (safe drop first)
DROP POLICY IF EXISTS "Admins can manage settings" ON public.app_settings;
CREATE POLICY "Admins can manage settings" ON public.app_settings
    FOR ALL
    TO authenticated
    USING ((SELECT role FROM public.users WHERE id = auth.uid()) = 'admin')
    WITH CHECK ((SELECT role FROM public.users WHERE id = auth.uid()) = 'admin');

-- Ensure investor_requests has the column too
ALTER TABLE public.investor_requests
ADD COLUMN IF NOT EXISTS admin_bank_details jsonb;
