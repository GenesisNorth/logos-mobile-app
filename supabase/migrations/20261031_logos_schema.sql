-- LOGOS IN ME: Phase 1 Cloud Database Schema
-- Supabase Postgres Migration with Row-Level Security (RLS)

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

-- 2. COVENANTS TABLE
CREATE TABLE IF NOT EXISTS public.covenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    signature_text TEXT NOT NULL,
    signed_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT unique_user_covenant UNIQUE (user_id)
);

-- 3. JOURNEY PROGRESS TABLE (Active sacred rhythm state)
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

-- 4. TEAR SHEETS TABLE (Day 4 burden dissolve ritual records)
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

-- 5. COMMUNITY PRAYERS & ROOMS
CREATE TABLE IF NOT EXISTS public.community_prayers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    author_name TEXT NOT NULL DEFAULT 'Pilgrim',
    room TEXT NOT NULL DEFAULT 'the_well', -- 'the_well', 'prayer_circles', 'valley', etc.
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    voice_note_url TEXT,
    pastor_name TEXT,
    pastor_response TEXT,
    prayed_count INT DEFAULT 0,
    is_answered BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);


-- ENABLE ROW LEVEL SECURITY
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.covenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journey_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tear_sheets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_prayers ENABLE ROW LEVEL SECURITY;

-- POLICIES: PROFILES
CREATE POLICY "Users can view their own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- POLICIES: COVENANTS
CREATE POLICY "Users can view their own covenant"
    ON public.covenants FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own covenant"
    ON public.covenants FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own covenant"
    ON public.covenants FOR UPDATE
    USING (auth.uid() = user_id);

-- POLICIES: JOURNEY PROGRESS
CREATE POLICY "Users can view their own journey progress"
    ON public.journey_progress FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can upsert their own journey progress"
    ON public.journey_progress FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- POLICIES: TEAR SHEETS
CREATE POLICY "Users can view their own tear sheets"
    ON public.tear_sheets FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own tear sheets"
    ON public.tear_sheets FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- POLICIES: COMMUNITY PRAYERS
CREATE POLICY "Anyone can view community prayers"
    ON public.community_prayers FOR SELECT
    TO authenticated, anon
    USING (true);

CREATE POLICY "Authenticated or anonymous users can share prayers"
    ON public.community_prayers FOR INSERT
    TO authenticated, anon
    WITH CHECK (true);

CREATE POLICY "Anyone can update prayer intercession count"
    ON public.community_prayers FOR UPDATE
    TO authenticated, anon
    USING (true)
    WITH CHECK (true);

-- TRIGGER: Auto-create profile on auth sign up
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
