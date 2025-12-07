-- Add transaction details to investor_requests
ALTER TABLE investor_requests 
ADD COLUMN IF NOT EXISTS transaction_utr TEXT,
ADD COLUMN IF NOT EXISTS transaction_date TIMESTAMP WITH TIME ZONE;

-- Create payouts table
CREATE TABLE IF NOT EXISTS payouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL REFERENCES investor_requests(id) ON DELETE CASCADE,
  amount NUMERIC NOT NULL,
  transaction_utr TEXT,
  payment_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  type TEXT NOT NULL DEFAULT 'Profit', -- 'Profit', 'Principal', 'Bonus'
  status TEXT NOT NULL DEFAULT 'Paid', -- 'Paid', 'Scheduled'
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies for payouts
ALTER TABLE payouts ENABLE ROW LEVEL SECURITY;

-- Admins can do everything
-- Using 'users' table and checking 'role' column as identified in codebase
CREATE POLICY "Admins can do everything on payouts" 
ON payouts FOR ALL 
USING (
  auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
);

-- Users can view their own payouts
CREATE POLICY "Users can view their own payouts" 
ON payouts FOR SELECT 
USING (
  request_id IN (SELECT id FROM investor_requests WHERE user_id = auth.uid())
);
