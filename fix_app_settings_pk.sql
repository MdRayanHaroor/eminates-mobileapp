-- Add ID column with auto-generation
ALTER TABLE public.app_settings 
ADD COLUMN IF NOT EXISTS id uuid DEFAULT gen_random_uuid();

-- Make it the Primary Key
ALTER TABLE public.app_settings 
ADD PRIMARY KEY (id);

-- Verify other columns exist (just in case)
ALTER TABLE public.app_settings 
ADD COLUMN IF NOT EXISTS description text,
ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true,
ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now(),
ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
