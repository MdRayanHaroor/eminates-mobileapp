-- Add new columns to investment_plans
ALTER TABLE public.investment_plans
ADD COLUMN IF NOT EXISTS monthly_profit_percentage numeric DEFAULT 2.0,
ADD COLUMN IF NOT EXISTS tenure_details jsonb DEFAULT '{"3": 30, "4": 40, "5": 50, "10": 100}'::jsonb;

-- Add new columns to investor_requests to store user selection
ALTER TABLE public.investor_requests
ADD COLUMN IF NOT EXISTS selected_tenure int,
ADD COLUMN IF NOT EXISTS maturity_bonus_percentage numeric;
