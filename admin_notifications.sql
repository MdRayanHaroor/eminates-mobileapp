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
    EXCEPTION WHEN OTHERS THEN
        -- Prevent blocking the transaction on notification error
        RAISE WARNING 'Error in handle_new_request_for_admin: %', SQLERRM;
    END;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

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
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_utr_submission_admin ON public.investor_requests;
CREATE TRIGGER on_utr_submission_admin
AFTER UPDATE ON public.investor_requests
FOR EACH ROW
EXECUTE FUNCTION handle_utr_submission_for_admin();

-- Trigger: New User Signup
CREATE OR REPLACE FUNCTION handle_new_user_signup_for_admin()
RETURNS TRIGGER AS $$
BEGIN
    BEGIN
        PERFORM notify_all_admins(
            'New User Signup',
            'A new user has signed up.',
            'info',
            NEW.id,
            'user'
        );
    EXCEPTION WHEN OTHERS THEN
         RAISE WARNING 'Error in handle_new_user_signup_for_admin: %', SQLERRM;
    END;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_new_user_signup_admin ON public.users;
CREATE TRIGGER on_new_user_signup_admin
AFTER INSERT ON public.users
FOR EACH ROW
EXECUTE FUNCTION handle_new_user_signup_for_admin();
