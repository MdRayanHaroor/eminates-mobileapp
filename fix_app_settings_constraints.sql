-- Remove unique constraint from 'key' column if it exists
DO $$ 
BEGIN 
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'app_settings_key_key') THEN
        ALTER TABLE public.app_settings DROP CONSTRAINT app_settings_key_key;
    END IF;
END $$;

-- Also try dropping generic index just in case it wasn't a named constraint
DROP INDEX IF EXISTS public.app_settings_key_key;

-- Backfill missing values for existing rows to ensure they show up in UI
UPDATE public.app_settings 
SET is_active = true 
WHERE is_active IS NULL;

UPDATE public.app_settings 
SET description = 'Bank Account' 
WHERE description IS NULL;
