-- Add commission_percentage to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS commission_percentage NUMERIC DEFAULT 0;

-- Comment on column
COMMENT ON COLUMN public.users.commission_percentage IS 'Commission percentage for agents';
