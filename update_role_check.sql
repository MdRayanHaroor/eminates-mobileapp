-- Drop the existing constraint
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_role_check;

-- Add the updated constraint including 'agent'
ALTER TABLE public.users
ADD CONSTRAINT users_role_check 
CHECK (role IN ('user', 'admin', 'agent'));

-- Verify
COMMENT ON CONSTRAINT users_role_check ON public.users IS 'Enforces valid roles: user, admin, agent';
