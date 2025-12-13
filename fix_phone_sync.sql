-- 1. Ensure phone column exists (Idempotent)
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS phone TEXT;

-- 2. Update existing users by stripping non-digits from metadata phone
-- This updates "public.users" with the normalized phone number from "auth.users" metadata
UPDATE public.users u
SET phone = REGEXP_REPLACE(
    COALESCE(au.phone, au.raw_user_meta_data->>'phone'), 
    '[^\d+]', -- Regex to match anything NOT a digit or +
    '', 
    'g' -- 'g' for global replacement
)
FROM auth.users au
WHERE u.id = au.id
  AND (
      u.phone IS NULL 
      OR u.phone = ''
      -- Or if the existing phone is un-sanitized (contains spaces/dashes), fix it
      OR u.phone ~ '[^\d+]'
  );

-- 3. Update the Sync Function to also sanitize logic
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, role, phone)
  VALUES (
    NEW.id, 
    NEW.email, 
    NEW.raw_user_meta_data->>'full_name',
    'user', 
    -- Sanitize on Insert
    REGEXP_REPLACE(
        COALESCE(NEW.phone, NEW.raw_user_meta_data->>'phone'), 
        '[^\d+]', '', 'g'
    )
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name,
    phone = EXCLUDED.phone;

  -- Notify Admins (Logic preserved)
  BEGIN
      PERFORM public.notify_all_admins(
          'New User Signup',
          'A new user (' || COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email, 'Unknown') || ') has signed up.',
          'info',
          NEW.id,
          'user'
      );
      
      INSERT INTO public.notifications (
          user_id, title, message, type, related_entity_id, related_entity_type, is_read
        ) VALUES (
            NEW.id, 'Welcome to Eminates', 'Welcome to the Eminates family!', 'info', NEW.id, 'user', false
        );
  EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'Failed to notify: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
