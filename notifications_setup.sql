-- Create a table for storing in-app notifications
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT CHECK (type IN ('info', 'success', 'warning', 'error')) DEFAULT 'info',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    related_entity_id UUID,
    related_entity_type TEXT
);

-- Enable RLS for notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Policy: Users can see their own notifications
CREATE POLICY "Users can view their own notifications"
ON public.notifications
FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Users can update their own notifications (e.g. mark as read)
CREATE POLICY "Users can update their own notifications"
ON public.notifications
FOR UPDATE
USING (auth.uid() = user_id);

-- Create a table for storing FCM tokens
CREATE TABLE IF NOT EXISTS public.user_fcm_tokens (
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    fcm_token TEXT NOT NULL,
    device_type TEXT, -- 'android', 'ios', 'web'
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    PRIMARY KEY (user_id, fcm_token)
);

-- Enable RLS for FCM tokens
ALTER TABLE public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Policy: Users can insert/update their own tokens
CREATE POLICY "Users can manage their own FCM tokens"
ON public.user_fcm_tokens
FOR ALL
USING (auth.uid() = user_id);

-- Create a function to update the updated_at column automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_fcm_tokens_updated_at
BEFORE UPDATE ON public.user_fcm_tokens
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();
