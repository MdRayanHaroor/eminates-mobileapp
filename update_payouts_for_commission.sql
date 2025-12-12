-- 1. Drop existing policies to recreate them with clearer logic
DROP POLICY IF EXISTS "Users can view their own payouts" ON payouts;

-- 2. Create Policy for Investors (Standard Payouts)
-- They should see payouts linked to their requests, BUT NOT 'Commission' type.
CREATE POLICY "Users can view their own payouts" 
ON payouts FOR SELECT 
USING (
  request_id IN (
    SELECT id FROM investor_requests WHERE user_id = auth.uid()
  )
  AND type != 'Commission'
);

-- 3. Create Policy for Agents (Commission Payouts)
-- They should see payouts linked to requests belonging to users THEY referred.
CREATE POLICY "Agents can view their commissions" 
ON payouts FOR SELECT 
USING (
  type = 'Commission'
  AND
  request_id IN (
    SELECT r.id 
    FROM investor_requests r
    JOIN users u ON r.user_id = u.id
    WHERE u.referred_by = auth.uid()
  )
);

-- 4. Admin Policy (Ensure it remains broad)
-- "Admins can do everything on payouts" likely already exists but let's ensure it covers everything
DROP POLICY IF EXISTS "Admins can do everything on payouts" ON payouts;
CREATE POLICY "Admins can do everything on payouts" 
ON payouts FOR ALL 
USING (
  auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
);

-- 5. No schema change needed for 'type' if it's just TEXT. 
-- If there was a check constraint, we might need to update it, but previous files showed generic TEXT or check.
-- Let's safely add the check constraint if it doesn't exist or update it.
-- Actually, let's just allow 'Commission' by not restricting it too much. 
-- Ideally we add a constraint.
ALTER TABLE payouts DROP CONSTRAINT IF EXISTS payouts_type_check;
ALTER TABLE payouts ADD CONSTRAINT payouts_type_check 
  CHECK (type IN ('Profit', 'Principal', 'Bonus', 'Commission'));
