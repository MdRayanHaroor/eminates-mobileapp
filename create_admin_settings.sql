-- Create app_settings table for dynamic configurations
CREATE TABLE IF NOT EXISTS public.app_settings (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    key text NOT NULL, -- e.g., 'bank_details'
    value jsonb NOT NULL, -- e.g., { "bank_name": "HDFC", "account_no": "123..." }
    description text, -- e.g., "Primary HDFC Account"
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- Policy: Admin can do everything
DROP POLICY IF EXISTS "Admins can manage settings" ON public.app_settings;

CREATE POLICY "Admins can manage settings" ON public.app_settings
    FOR ALL
    TO authenticated
    USING ((SELECT role FROM public.users WHERE id = auth.uid()) = 'admin')
    WITH CHECK ((SELECT role FROM public.users WHERE id = auth.uid()) = 'admin');

-- Policy: Authenticated users can read active settings (needed for UTR screen? NO, specific request links it)
-- Actually, user needs to read nothing from here directly if we copy details to request.
-- BUT, if we link by ID, user needs read access to specific ID.
-- Let's copy details to request table for immutability.

-- Add column to investor_requests to store the SNAPSHOT of bank details
ALTER TABLE public.investor_requests
ADD COLUMN IF NOT EXISTS admin_bank_details jsonb;
