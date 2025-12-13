-- Update the lookup function to be smarter about phone number formats
-- It compares the last 10 digits of the stored phone and the input phone
-- This handles cases where one has countyr code (+91) and the other doesn't

CREATE OR REPLACE FUNCTION public.get_email_by_phone(phone_number text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  found_email text;
  clean_input text;
BEGIN
  -- Remove non-digits from input
  clean_input := regexp_replace(phone_number, '[^\d]', '', 'g');

  SELECT email INTO found_email
  FROM public.users
  WHERE 
    -- Compare last 10 digits (handles +91 vs local)
    RIGHT(regexp_replace(phone, '[^\d]', '', 'g'), 10) = RIGHT(clean_input, 10)
  LIMIT 1;
  
  RETURN found_email;
END;
$$;

-- Ensure permissions (in case they were reset)
GRANT EXECUTE ON FUNCTION public.get_email_by_phone(text) TO anon;
GRANT EXECUTE ON FUNCTION public.get_email_by_phone(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_email_by_phone(text) TO service_role;
