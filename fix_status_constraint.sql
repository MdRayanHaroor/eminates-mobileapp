-- Drop the existing check constraint
ALTER TABLE investor_requests 
DROP CONSTRAINT IF EXISTS investor_requests_status_check;

-- Re-add the check constraint with the new allowed values
ALTER TABLE investor_requests 
ADD CONSTRAINT investor_requests_status_check 
CHECK (status IN (
  'Draft', 
  'Pending', 
  'Approved', 
  'Rejected', 
  'UTR Submitted', 
  'Investment Confirmed'
));
