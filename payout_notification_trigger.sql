-- Function to handle new payouts
CREATE OR REPLACE FUNCTION handle_new_payout()
RETURNS TRIGGER AS $$
DECLARE
    target_user_id UUID;
BEGIN
    -- Get the user_id associated with the investment request
    SELECT user_id INTO target_user_id
    FROM public.investor_requests
    WHERE id = NEW.request_id;

    -- If user found, send notification
    IF target_user_id IS NOT NULL THEN
        INSERT INTO public.notifications (
            user_id,
            title,
            message,
            type,
            related_entity_id,
            related_entity_type
        ) VALUES (
            target_user_id,
            'New Payout Received',
            'You have received a payout of ' || NEW.amount || ' (' || NEW.type || ').',
            'success',
            NEW.id,
            'payout'
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create Trigger
DROP TRIGGER IF EXISTS on_new_payout ON public.payouts;

CREATE TRIGGER on_new_payout
AFTER INSERT ON public.payouts
FOR EACH ROW
EXECUTE FUNCTION handle_new_payout();
