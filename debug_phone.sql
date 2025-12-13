-- Run this query to see specific user details
-- Replace '7829751480' with the number you are trying to use if different
SELECT id, email, phone, raw_user_meta_data 
FROM public.users 
WHERE phone LIKE '%7829751480%' 
   OR raw_user_meta_data->>'phone' LIKE '%7829751480%';

-- Check total count of users with valid phone numbers
SELECT count(*) as total_users_with_phone 
FROM public.users 
WHERE phone IS NOT NULL;
