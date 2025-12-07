-- Ensure columns exist (Idempotent)
ALTER TABLE investor_requests 
ADD COLUMN IF NOT EXISTS transaction_utr TEXT,
ADD COLUMN IF NOT EXISTS transaction_date TIMESTAMP WITH TIME ZONE;

-- Drop policy if it exists to avoid "already exists" error, then recreate it
DROP POLICY IF EXISTS "Users can update their own requests" ON investor_requests;

-- Allow users to update their own requests (needed for submitting UTR)
CREATE POLICY "Users can update their own requests"
ON investor_requests FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Ensure payouts table exists
CREATE TABLE IF NOT EXISTS payouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL REFERENCES investor_requests(id) ON DELETE CASCADE,
  amount NUMERIC NOT NULL,
  transaction_utr TEXT,
  payment_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  type TEXT NOT NULL DEFAULT 'Profit',
  status TEXT NOT NULL DEFAULT 'Paid',
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on payouts
ALTER TABLE payouts ENABLE ROW LEVEL SECURITY;

-- Re-apply Payout policies safely
DROP POLICY IF EXISTS "Admins can do everything on payouts" ON payouts;
DROP POLICY IF EXISTS "Users can view their own payouts" ON payouts;

CREATE POLICY "Admins can do everything on payouts" 
ON payouts FOR ALL 
USING (
  auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
);

CREATE POLICY "Users can view their own payouts" 
ON payouts FOR SELECT 
USING (
  request_id IN (SELECT id FROM investor_requests WHERE user_id = auth.uid())
);
