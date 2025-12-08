-- 1. Check if public.users exists and see columns (Pseudo-check by selecting)
SELECT * FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users';

-- 2. Count Admins
SELECT count(*) as admin_count FROM public.users WHERE role = 'admin';

-- 3. Show all users and their roles (Limit 10)
SELECT id, email, role FROM public.users LIMIT 10;

-- 4. Test the notify function manually (if admins exist)
-- This tries to insert a notification. If this works (and you see a notification), 
-- then the issue is the Triggers (on_insert/user_signup).
-- If this creates 0 notifications, the issue is that the loop finds no admins.
SELECT notify_all_admins(
    'Manual Test',
    'Testing if admins exist',
    'info',
    null,
    null
);
