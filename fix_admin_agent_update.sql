-- Enable RLS on users table (it should be already, but ensuring)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Allow Admins to UPDATE any user's profile (needed for editing Agents)
CREATE POLICY "Admins can update all users"
ON public.users
FOR UPDATE
TO authenticated
USING (
  (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
)
WITH CHECK (
  (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
);

-- Note: Existing policies probably allow users to update their OWN profile.
-- This new policy specifically grants Admins the right to update others (Agents).
