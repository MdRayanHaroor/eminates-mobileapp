-- 1. Ensure public.users table exists (It does, based on error)
-- We skip creating it.

-- 2. Create/Update the Sync Function
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, role)
  VALUES (
    NEW.id, 
    NEW.email, 
    NEW.raw_user_meta_data->>'full_name',
    'user' -- Default role
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name;

  -- DIRECTLY Notify Admins (Avoids relying on secondary trigger)
  -- We wrap in BEGIN/EXCEPTION to ensure user creation never fails even if notification fails
  BEGIN
      PERFORM public.notify_all_admins(
          'New User Signup',
          'A new user (' || COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email, 'Unknown') || ') has signed up.',
          'info',
          NEW.id,
          'user'
      );
  EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'Failed to notify admins on signup: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create the Trigger on auth.users
-- Note: We must drop it first to avoid duplicates or errors if it exists with different name
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();

-- 4. Backfill existing users (Crucial Step)
INSERT INTO public.users (id, email, full_name, role)
SELECT 
    id, 
    email, 
    raw_user_meta_data->>'full_name',
    'user'
FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- 5. Verification
-- Verify the count of users in public.users vs auth.users
-- We use an anonymous code block which shouldn't cause syntax errors if run as a script in Supabase
DO $$
DECLARE
  v_public_count INT;
  v_auth_count INT;
BEGIN
  SELECT count(*) INTO v_public_count FROM public.users;
  SELECT count(*) INTO v_auth_count FROM auth.users;
  RAISE NOTICE 'Public Users: %, Auth Users: %', v_public_count, v_auth_count;
END $$;
