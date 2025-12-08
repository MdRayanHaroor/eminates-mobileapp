-- Function to handle status changes
CREATE OR REPLACE FUNCTION handle_request_status_change()
RETURNS TRIGGER AS $$
DECLARE
    notification_title TEXT;
    notification_body TEXT;
    notification_type TEXT;
BEGIN
    -- Only trigger if status has changed
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        
        -- Default values
        notification_title := 'Request Update';
        notification_type := 'info';

        -- Customize message based on status (case-insensitive check if needed, but usually exact matches)
        IF NEW.status = 'Approved' THEN
            notification_title := 'Request Approved';
            notification_body := 'Your investment request has been approved. Please submit your UTR details.';
            notification_type := 'success';
        ELSIF NEW.status = 'Rejected' THEN
            notification_title := 'Request Rejected';
            notification_body := 'Your investment request was not approved. Please contact support for details.';
            notification_type := 'error';
        ELSIF NEW.status = 'Investment Confirmed' THEN
            notification_title := 'Investment Confirmed';
            notification_body := 'Your payment has been verified and investment is active.';
            notification_type := 'success';
        ELSIF NEW.status = 'UTR Submitted' THEN
            notification_title := 'UTR Received';
            notification_body := 'We have received your UTR submission and are verifying it.';
            notification_type := 'info';
        ELSE
            notification_body := 'Your request status has changed to: ' || NEW.status;
        END IF;

        -- Insert into notifications table
        INSERT INTO public.notifications (
            user_id,
            title,
            message,
            type,
            related_entity_id,
            related_entity_type
        ) VALUES (
            NEW.user_id,
            notification_title,
            notification_body,
            notification_type,
            NEW.id,
            'investment_request'
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create Trigger
DROP TRIGGER IF EXISTS on_request_status_change ON public.investor_requests;

CREATE TRIGGER on_request_status_change
AFTER UPDATE ON public.investor_requests
FOR EACH ROW
EXECUTE FUNCTION handle_request_status_change();
