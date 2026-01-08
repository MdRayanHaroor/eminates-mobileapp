-- Function to notify all admins
CREATE OR REPLACE FUNCTION notify_all_admins(
    p_title TEXT,
    p_message TEXT,
    p_type TEXT,
    p_entity_id UUID,
    p_entity_type TEXT
)
RETURNS VOID AS $$
DECLARE
    admin_record RECORD;
BEGIN
    -- Loop through all users with role 'admin'
    FOR admin_record IN SELECT id FROM public.users WHERE role = 'admin'
    LOOP
        INSERT INTO public.notifications (
            user_id,
            title,
            message,
            type,
            related_entity_id,
            related_entity_type,
            is_read
        ) VALUES (
            admin_record.id,
            p_title,
            p_message,
            p_type,
            p_entity_id,
            p_entity_type,
            false
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: New Investment Request
CREATE OR REPLACE FUNCTION handle_new_request_for_admin()
RETURNS TRIGGER AS $$
BEGIN
    BEGIN
        PERFORM notify_all_admins(
            'New Investment Request',
            'A new investment request has been submitted by ' || COALESCE(NEW.full_name, 'Unknown User'),
            'info',
            NEW.id,
            'investor_request'
        );

        -- Notify User (Request Received)
        INSERT INTO public.notifications (
            user_id,
            title,
            message,
            type,
            related_entity_id,
            related_entity_type,
            is_read
        ) VALUES (
            NEW.user_id,
            'Request Received',
            'Your investment request has been submitted successfully and is currently under review.',
            'info',
            NEW.id,
            'investment_request',
            false
        );
    EXCEPTION WHEN OTHERS THEN
        -- Prevent blocking the transaction on notification error
        RAISE WARNING 'Error in handle_new_request_for_admin: %', SQLERRM;
    END;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_new_request_admin ON public.investor_requests;
CREATE TRIGGER on_new_request_admin
AFTER INSERT ON public.investor_requests
FOR EACH ROW
EXECUTE FUNCTION handle_new_request_for_admin();

-- Trigger: UTR Submitted
CREATE OR REPLACE FUNCTION handle_utr_submission_for_admin()
RETURNS TRIGGER AS $$
BEGIN
    BEGIN
        -- Check if status changed to 'UTR Submitted'
        IF OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'UTR Submitted' THEN
            PERFORM notify_all_admins(
                'UTR Submitted',
                'User ' || COALESCE(NEW.full_name, 'Unknown User') || ' has submitted UTR details for verification.',
                'warning',
                NEW.id,
                'investor_request'
            );
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Error in handle_utr_submission_for_admin: %', SQLERRM;
    END;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_utr_submission_admin ON public.investor_requests;
CREATE TRIGGER on_utr_submission_admin
AFTER UPDATE ON public.investor_requests
FOR EACH ROW
EXECUTE FUNCTION handle_utr_submission_for_admin();

-- Trigger: New User Signup (MOVED TO ensure_user_sync.sql)
-- We drop this trigger to verify there are no duplicates.
DROP TRIGGER IF EXISTS on_new_user_signup_admin ON public.users;
DROP FUNCTION IF EXISTS handle_new_user_signup_for_admin();
