-- Add rejection_reason column to investor_requests
ALTER TABLE public.investor_requests
ADD COLUMN IF NOT EXISTS rejection_reason TEXT;
