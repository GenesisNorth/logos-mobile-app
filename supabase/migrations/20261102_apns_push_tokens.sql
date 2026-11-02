-- LOGOS IN ME: Phase 6 APNS & Push Notification Token Registration
-- Table and RLS policies for Apple Push Notification Service (APNS) & FCM tokens

CREATE TABLE IF NOT EXISTS public.device_push_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    device_token TEXT NOT NULL UNIQUE,
    platform TEXT NOT NULL DEFAULT 'ios', -- 'ios' (APNS) or 'android' (FCM)
    environment TEXT NOT NULL DEFAULT 'production', -- 'sandbox' or 'production'
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    last_registered_at TIMESTAMPTZ DEFAULT now()
);

-- Index for speedy push notifications lookups during midnight strikes & liturgical chimes
CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON public.device_push_tokens (user_id);
CREATE INDEX IF NOT EXISTS idx_device_tokens_active ON public.device_push_tokens (is_active, platform);

-- ENABLE ROW LEVEL SECURITY
ALTER TABLE public.device_push_tokens ENABLE ROW LEVEL SECURITY;

-- POLICIES: DEVICE PUSH TOKENS
CREATE POLICY "Users can view their own registered push tokens"
    ON public.device_push_tokens FOR SELECT
    TO authenticated, anon
    USING (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can register or upsert their push tokens"
    ON public.device_push_tokens FOR INSERT
    TO authenticated, anon
    WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can update their push tokens"
    ON public.device_push_tokens FOR UPDATE
    TO authenticated, anon
    USING (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Users can delete their push tokens"
    ON public.device_push_tokens FOR DELETE
    TO authenticated, anon
    USING (auth.uid() = user_id OR user_id IS NULL);
