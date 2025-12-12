-- Add plan_name column to investor_requests
-- Constraint: TEXT, NOT NULL, Default 'Draft'

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'investor_requests' AND column_name = 'plan_name') THEN
        ALTER TABLE public.investor_requests 
        ADD COLUMN plan_name text NOT NULL DEFAULT 'Draft';
    END IF;
END $$;
