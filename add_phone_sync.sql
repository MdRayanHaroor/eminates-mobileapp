-- 1. Add phone column to users table if it doesn't exist
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS phone TEXT;

-- 2. Update the sync function to include phone
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, role, phone)
  VALUES (
    NEW.id, 
    NEW.email, 
    NEW.raw_user_meta_data->>'full_name',
    'user', -- Default role
    COALESCE(NEW.phone, NEW.raw_user_meta_data->>'phone') -- Prioritize auth.phone, fallback to metadata
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name,
    phone = EXCLUDED.phone;

  -- Notifications logic remains the same...
  -- (We don't need to rewrite the whole notification block if we just want to update the insert/update logic, 
  -- but strictly logically, we should include the full body to replace the function. 
  -- For brevity in this thought process, I assume I'd write the full function.)
  
  -- DIRECTLY Notify Admins
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

-- 3. Backfill/Update existing users to sync phone from auth.users (metadata or phone col)
UPDATE public.users u
SET phone = COALESCE(au.phone, au.raw_user_meta_data->>'phone')
FROM auth.users au
WHERE u.id = au.id
AND u.phone IS NULL;
