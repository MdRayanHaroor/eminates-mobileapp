-- Enable RLS
ALTER TABLE public.investor_requests ENABLE ROW LEVEL SECURITY;

-- Policy: Agents can view requests of users referred by them
DROP POLICY IF EXISTS "Agents can view referred requests" ON public.investor_requests;
CREATE POLICY "Agents can view referred requests" 
ON public.investor_requests FOR SELECT 
TO authenticated 
USING (
  EXISTS (
    SELECT 1 FROM public.users 
    WHERE public.users.id = public.investor_requests.user_id 
    AND public.users.referred_by = auth.uid()
  )
);
