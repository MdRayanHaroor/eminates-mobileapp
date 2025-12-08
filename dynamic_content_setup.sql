-- 1. Investment Plans Table
CREATE TABLE IF NOT EXISTS public.investment_plans (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    min_amount NUMERIC NOT NULL,
    max_amount NUMERIC NOT NULL,
    roi_percentage NUMERIC NOT NULL, -- Annual ROI
    duration_months INTEGER NOT NULL,
    description TEXT,
    features TEXT[], -- Array of feature strings
    is_custom BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.investment_plans ENABLE ROW LEVEL SECURITY;

-- Policy: Everyone can view active plans
CREATE POLICY "Everyone can view active plans" 
ON public.investment_plans FOR SELECT 
USING (is_active = true OR (auth.uid() IN (SELECT id FROM users WHERE role = 'admin')));

-- Policy: Only Admins can insert/update/delete
CREATE POLICY "Admins can manage plans" 
ON public.investment_plans FOR ALL 
USING (auth.uid() IN (SELECT id FROM users WHERE role = 'admin'));

-- Initial Data (Real Plans from App)
INSERT INTO public.investment_plans (name, min_amount, max_amount, roi_percentage, duration_months, description, features, is_custom)
VALUES 
('Silver Plan', 300000, 300000, 24.0, 36, 'Consistent returns with quarterly payouts.', ARRAY['Quarterly Payout', 'Approx 24% Annual ROI', '3 Year Tenure'], false),
('Gold Plan', 500000, 500000, 30.0, 72, 'High growth with half-yearly payouts.', ARRAY['Half-yearly Payout', '~30% Annual ROI', '6 Year Tenure'], false),
('Platinum Plan', 1000000, 1000000, 36.0, 72, 'Maximize wealth with yearly payouts.', ARRAY['Yearly Payout', '~36% Annual ROI', '6 Year Tenure'], false),
('Elite Plan', 2500000, 100000000, 36.0, 60, 'Tailored for HNI investors.', ARRAY['Yearly/Agreement Payout', 'Custom ROI', '5-7 Year Tenure'], true);


-- 2. App Settings Table (Key-Value Store for Bank Details etc)
CREATE TABLE IF NOT EXISTS public.app_settings (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL, -- Flexible storage
    description TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- Policy: Everyone can view settings
CREATE POLICY "Everyone can view settings" 
ON public.app_settings FOR SELECT 
USING (true);

-- Policy: Only Admins can modify settings
CREATE POLICY "Admins can manage settings" 
ON public.app_settings FOR ALL 
USING (auth.uid() IN (SELECT id FROM users WHERE role = 'admin'));

-- Initial Data (Bank Details)
INSERT INTO public.app_settings (key, value, description)
VALUES (
    'bank_details',
    '{
        "bank_name": "HDFC Bank",
        "account_holder": "Eminates Investment",
        "account_number": "50200012345678",
        "ifsc_code": "HDFC0001234"
    }'::jsonb,
    'Bank account details for user deposits'
) ON CONFLICT (key) DO NOTHING;
