-- Add columns for payout percentages if they don't exist
ALTER TABLE public.investment_plans 
ADD COLUMN IF NOT EXISTS quarterly_profit_percentage NUMERIC DEFAULT 7.0,
ADD COLUMN IF NOT EXISTS half_yearly_profit_percentage NUMERIC DEFAULT 16.0;

-- Update existing rows to have default values if they are null (just in case)
UPDATE public.investment_plans
SET quarterly_profit_percentage = 7.0
WHERE quarterly_profit_percentage IS NULL;

UPDATE public.investment_plans
SET half_yearly_profit_percentage = 16.0
WHERE half_yearly_profit_percentage IS NULL;

-- Optional: Add check constraints to ensure reasonable values
ALTER TABLE public.investment_plans 
DROP CONSTRAINT IF EXISTS check_percentages_range;

ALTER TABLE public.investment_plans 
ADD CONSTRAINT check_percentages_range 
CHECK (
  quarterly_profit_percentage >= 0 AND quarterly_profit_percentage <= 100 AND
  half_yearly_profit_percentage >= 0 AND half_yearly_profit_percentage <= 100
);
