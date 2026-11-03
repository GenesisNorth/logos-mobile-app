-- ==============================================================================
-- LOGOS IN ME: Complete Master Supabase Setup & Cloud Migration
-- Single-file script: Run this once in the Supabase SQL Editor
-- ==============================================================================

-- 1. PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE,
    display_name TEXT DEFAULT 'Beloved Pilgrim',
    streak_count INT DEFAULT 0,
    grace_tokens INT DEFAULT 3,
    roots_count INT DEFAULT 0,
    birth_month INT DEFAULT 1,
    birth_day INT DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. COVENANTS TABLE (Liturgical Manifesto Digital Signature)
CREATE TABLE IF NOT EXISTS public.covenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    signature_text TEXT NOT NULL,
    signed_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT unique_user_covenant UNIQUE (user_id)
);

-- 3. JOURNEY PROGRESS TABLE (Active 4-Day Sacred Rhythm State & Curriculum)
CREATE TABLE IF NOT EXISTS public.journey_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    week_index INT NOT NULL DEFAULT 0,
    active_day INT NOT NULL DEFAULT 1,
    preferred_translation TEXT NOT NULL DEFAULT 'ESV',
    day_completion JSONB NOT NULL DEFAULT '{"1": false, "2": false, "3": false, "4": false}'::jsonb,
    day_completed_at JSONB NOT NULL DEFAULT '{}'::jsonb,
    day_recitation_count JSONB NOT NULL DEFAULT '{"1": 0, "2": 0, "3": 0, "4": 0}'::jsonb,
    is_exchange_completed BOOLEAN NOT NULL DEFAULT false,
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT unique_user_journey UNIQUE (user_id)
);

-- 4. TEAR SHEETS TABLE (Day 4 Holy Altar Burden Dissolve Ritual Records)
CREATE TABLE IF NOT EXISTS public.tear_sheets (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    drop_id TEXT NOT NULL,
    verse_text TEXT NOT NULL,
    reference TEXT NOT NULL,
    burden_hash TEXT NOT NULL,
    tear_sheet_image_path TEXT,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 5. COMMUNITY PRAYERS & PASTORAL WATCH ROOMS
CREATE TABLE IF NOT EXISTS public.community_prayers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    author_name TEXT NOT NULL DEFAULT 'Pilgrim',
    room TEXT NOT NULL DEFAULT 'the_well', -- 'the_well', 'prayer_circles', 'valley'
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    voice_note_url TEXT,
    pastor_name TEXT,
    pastor_response TEXT,
    prayed_count INT DEFAULT 0,
    is_answered BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 6. DEVICE PUSH TOKENS TABLE (APNS for iOS & FCM for Android)
CREATE TABLE IF NOT EXISTS public.device_push_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    device_token TEXT NOT NULL UNIQUE,
    platform TEXT NOT NULL DEFAULT 'ios', -- 'ios' or 'android'
    environment TEXT NOT NULL DEFAULT 'production', -- 'sandbox' or 'production'
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    last_registered_at TIMESTAMPTZ DEFAULT now()
);

-- ==============================================================================
-- PERFORMANCE INDEXES
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_covenants_user ON public.covenants (user_id);
CREATE INDEX IF NOT EXISTS idx_journey_user ON public.journey_progress (user_id);
CREATE INDEX IF NOT EXISTS idx_tear_sheets_user ON public.tear_sheets (user_id);
CREATE INDEX IF NOT EXISTS idx_prayers_room ON public.community_prayers (room, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON public.device_push_tokens (user_id);
CREATE INDEX IF NOT EXISTS idx_device_tokens_active ON public.device_push_tokens (is_active, platform);

-- ==============================================================================
-- ENABLE ROW LEVEL SECURITY (RLS)
-- ==============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.covenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journey_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tear_sheets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_prayers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_push_tokens ENABLE ROW LEVEL SECURITY;

-- ==============================================================================
-- RLS POLICIES
-- ==============================================================================

-- PROFILES
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
CREATE POLICY "Users can view their own profile"
    ON public.profiles FOR SELECT
    TO authenticated, anon
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile"
    ON public.profiles FOR INSERT
    TO authenticated, anon
    WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE
    TO authenticated, anon
    USING (auth.uid() = id);

-- COVENANTS
DROP POLICY IF EXISTS "Users can view their own covenant" ON public.covenants;
CREATE POLICY "Users can view their own covenant"
    ON public.covenants FOR SELECT
    TO authenticated, anon
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own covenant" ON public.covenants;
CREATE POLICY "Users can insert their own covenant"
    ON public.covenants FOR INSERT
    TO authenticated, anon
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own covenant" ON public.covenants;
CREATE POLICY "Users can update their own covenant"
    ON public.covenants FOR UPDATE
    TO authenticated, anon
    USING (auth.uid() = user_id);

-- JOURNEY PROGRESS
DROP POLICY IF EXISTS "Users can view their own journey progress" ON public.journey_progress;
CREATE POLICY "Users can view their own journey progress"
    ON public.journey_progress FOR SELECT
    TO authenticated, anon
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can upsert their own journey progress" ON public.journey_progress;
CREATE POLICY "Users can upsert their own journey progress"
    ON public.journey_progress FOR ALL
    TO authenticated, anon
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- TEAR SHEETS
DROP POLICY IF EXISTS "Users can view their own tear sheets" ON public.tear_sheets;
CREATE POLICY "Users can view their own tear sheets"
    ON public.tear_sheets FOR SELECT
    TO authenticated, anon
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own tear sheets" ON public.tear_sheets;
CREATE POLICY "Users can insert their own tear sheets"
    ON public.tear_sheets FOR INSERT
    TO authenticated, anon
    WITH CHECK (auth.uid() = user_id);

-- COMMUNITY PRAYERS
DROP POLICY IF EXISTS "Anyone can view community prayers" ON public.community_prayers;
CREATE POLICY "Anyone can view community prayers"
    ON public.community_prayers FOR SELECT
    TO authenticated, anon
    USING (true);

DROP POLICY IF EXISTS "Authenticated or anonymous users can share prayers" ON public.community_prayers;
CREATE POLICY "Authenticated or anonymous users can share prayers"
    ON public.community_prayers FOR INSERT
    TO authenticated, anon
    WITH CHECK (true);

DROP POLICY IF EXISTS "Anyone can update prayer intercession count" ON public.community_prayers;
CREATE POLICY "Anyone can update prayer intercession count"
    ON public.community_prayers FOR UPDATE
    TO authenticated, anon
    USING (true)
    WITH CHECK (true);

-- DEVICE PUSH TOKENS
DROP POLICY IF EXISTS "Users can view their own registered push tokens" ON public.device_push_tokens;
CREATE POLICY "Users can view their own registered push tokens"
    ON public.device_push_tokens FOR SELECT
    TO authenticated, anon
    USING (auth.uid() = user_id OR user_id IS NULL);

DROP POLICY IF EXISTS "Users can register or upsert their push tokens" ON public.device_push_tokens;
CREATE POLICY "Users can register or upsert their push tokens"
    ON public.device_push_tokens FOR INSERT
    TO authenticated, anon
    WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

DROP POLICY IF EXISTS "Users can update their push tokens" ON public.device_push_tokens;
CREATE POLICY "Users can update their push tokens"
    ON public.device_push_tokens FOR UPDATE
    TO authenticated, anon
    USING (auth.uid() = user_id OR user_id IS NULL);

DROP POLICY IF EXISTS "Users can delete their push tokens" ON public.device_push_tokens;
CREATE POLICY "Users can delete their push tokens"
    ON public.device_push_tokens FOR DELETE
    TO authenticated, anon
    USING (auth.uid() = user_id OR user_id IS NULL);

-- ==============================================================================
-- AUTH TRIGGER: AUTO-CREATE PROFILE ON SIGN UP
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, username, display_name)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', 'pilgrim_' || SUBSTRING(NEW.id::text FROM 1 FOR 6)),
        COALESCE(NEW.raw_user_meta_data->>'display_name', 'Beloved Pilgrim')
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==============================================================================
-- REALTIME BROADCAST REPLICATION (For live prayer streams)
-- ==============================================================================
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.community_prayers;
EXCEPTION WHEN OTHERS THEN
    NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.journey_progress;
EXCEPTION WHEN OTHERS THEN
    NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
EXCEPTION WHEN OTHERS THEN
    NULL;
END $$;

-- ==============================================================================
-- SEED DATA: COMMUNITY CLOISTER FEEDS (The Well, Prayer Circles, Valley)
-- ==============================================================================
INSERT INTO public.community_prayers (id, author_name, room, title, content, pastor_name, pastor_response, prayed_count, is_answered, created_at)
VALUES 
    (
        '550e8400-e29b-41d4-a716-446655440001'::uuid,
        'Genesis A.',
        'the_well',
        'Ministry Burnout & Exhaustion',
        'Navigating severe burnout in ministry and loneliness. Struggling to pray.',
        'Pastor Thomas M.',
        'Beloved Genesis, I carried your name to the altar this morning. Remember: your labor is not what justifies you; your abiding in Christ is your life. Rest your soul today.',
        14,
        true,
        now() - INTERVAL '18 hours'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440002'::uuid,
        'Sister Miriam',
        'the_well',
        'Waiting in Chronic Illness',
        'Facing another month of unknown diagnostic tests. Needing peace to stay grounded in Colossians 3.',
        'Pastor Ruth C.',
        'Miriam, your life is hidden with Christ in God. Disease touches the outer frame, but your eternal temple is untouched. We intercede for peace that transcends understanding.',
        22,
        true,
        now() - INTERVAL '2 days'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440003'::uuid,
        'Sarah K.',
        'prayer_circles',
        'Praying with you',
        'Lifting everyone walking through the quiet seasons today. His grace is abundant.',
        NULL,
        NULL,
        38,
        false,
        now() - INTERVAL '6 hours'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440004'::uuid,
        'David M.',
        'prayer_circles',
        'The peace of Christ guard you',
        'Standing in agreement for reconciliation and emotional healing in families.',
        NULL,
        NULL,
        19,
        false,
        now() - INTERVAL '14 hours'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440005'::uuid,
        'Pilgrim in Cloister',
        'valley',
        'Grief in the Quiet Hours',
        'Remembering my mother who went to be with the Lord. Anchoring in Psalm 23:4.',
        NULL,
        NULL,
        45,
        false,
        now() - INTERVAL '1 day'
    )
ON CONFLICT (id) DO NOTHING;
