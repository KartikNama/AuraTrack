-- ==============================================================================
-- AuraTrack - Complete Master Database Migration Script
-- Production-Ready Schema for Supabase PostgreSQL
-- ==============================================================================

-- 1. Enable Required Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 2. Create Core Enums and Types
-- ==============================================================================
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('admin', 'manager', 'employee');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE time_entry_status AS ENUM ('running', 'stopped', 'paused');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE time_entry_type AS ENUM ('automatic', 'manual');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE screenshot_type AS ENUM ('screen', 'camera');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ==============================================================================
-- 3. Create Tables
-- ==============================================================================

-- PROFILES (Users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    role user_role DEFAULT 'employee'::user_role NOT NULL,
    team TEXT,
    manager_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    screenshot_interval INTEGER DEFAULT 10 NOT NULL,
    allow_screenshot_capture BOOLEAN DEFAULT true NOT NULL,
    allow_camera_capture BOOLEAN DEFAULT false NOT NULL,
    force_password_change BOOLEAN DEFAULT false NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- CLIENTS
CREATE TABLE IF NOT EXISTS public.clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- PROJECTS
CREATE TABLE IF NOT EXISTS public.projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    client_id UUID REFERENCES public.clients(id) ON DELETE SET NULL,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    status TEXT DEFAULT 'active' NOT NULL,
    color TEXT DEFAULT '#06B6D4',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- TASKS
CREATE TABLE IF NOT EXISTS public.tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'todo' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- PROJECT MEMBERS
CREATE TABLE IF NOT EXISTS public.project_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(project_id, user_id)
);

-- GROUPS
CREATE TABLE IF NOT EXISTS public.groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- GROUP MEMBERS
CREATE TABLE IF NOT EXISTS public.group_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(group_id, user_id)
);

-- EMPLOYEE MANAGERS
CREATE TABLE IF NOT EXISTS public.employee_managers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    manager_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    manager_type TEXT DEFAULT 'direct' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(employee_id, manager_id, manager_type)
);

-- TIME ENTRIES
CREATE TABLE IF NOT EXISTS public.time_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    duration INTEGER DEFAULT 0 NOT NULL,
    status time_entry_status DEFAULT 'stopped'::time_entry_status NOT NULL,
    notes TEXT,
    entry_type time_entry_type DEFAULT 'automatic'::time_entry_type NOT NULL,
    app_version TEXT,
    manual_attachment_path TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- PROJECT TIME ENTRIES
CREATE TABLE IF NOT EXISTS public.project_time_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    time_entry_id UUID REFERENCES public.time_entries(id) ON DELETE CASCADE NOT NULL,
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- SCREENSHOTS
CREATE TABLE IF NOT EXISTS public.screenshots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    time_entry_id UUID REFERENCES public.time_entries(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    file_path TEXT NOT NULL,
    thumbnail_path TEXT,
    captured_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    type screenshot_type DEFAULT 'screen'::screenshot_type NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ACTIVITY LOGS
CREATE TABLE IF NOT EXISTS public.activity_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    screenshot_id UUID REFERENCES public.screenshots(id) ON DELETE CASCADE NOT NULL,
    keystrokes INTEGER DEFAULT 0 NOT NULL,
    mouse_movements INTEGER DEFAULT 0 NOT NULL,
    productivity_score NUMERIC(5,2) DEFAULT 0.00 NOT NULL,
    urls TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ATTENDANCE
CREATE TABLE IF NOT EXISTS public.attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    date DATE NOT NULL,
    clock_in_time TIMESTAMPTZ,
    clock_out_time TIMESTAMPTZ,
    status TEXT DEFAULT 'present' NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, date)
);

-- SYSTEM SETTINGS
CREATE TABLE IF NOT EXISTS public.system_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key TEXT UNIQUE NOT NULL,
    value JSONB NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- USER LOGS / AUDIT TRAIL
CREATE TABLE IF NOT EXISTS public.user_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    action TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    ip_address TEXT,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- IN-APP NOTIFICATIONS
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'info' NOT NULL,
    read BOOLEAN DEFAULT false NOT NULL,
    data JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 4. Create Indexes for High Performance
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);

CREATE INDEX IF NOT EXISTS idx_time_entries_user_id ON public.time_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_time_entries_start_time ON public.time_entries(start_time);
CREATE INDEX IF NOT EXISTS idx_time_entries_user_start ON public.time_entries(user_id, start_time DESC);

CREATE INDEX IF NOT EXISTS idx_screenshots_time_entry_id ON public.screenshots(time_entry_id);
CREATE INDEX IF NOT EXISTS idx_screenshots_user_id ON public.screenshots(user_id);
CREATE INDEX IF NOT EXISTS idx_screenshots_captured_at ON public.screenshots(captured_at DESC);
CREATE INDEX IF NOT EXISTS idx_screenshots_user_captured ON public.screenshots(user_id, captured_at DESC);

CREATE INDEX IF NOT EXISTS idx_activity_logs_screenshot_id ON public.activity_logs(screenshot_id);

CREATE INDEX IF NOT EXISTS idx_attendance_user_date ON public.attendance(user_id, date);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON public.attendance(date DESC);

CREATE INDEX IF NOT EXISTS idx_project_members_user ON public.project_members(user_id);
CREATE INDEX IF NOT EXISTS idx_project_members_project ON public.project_members(project_id);

CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON public.notifications(user_id, read) WHERE read = false;

-- ==============================================================================
-- 5. Helper Functions & Auth Triggers
-- ==============================================================================

-- Security helper to check user role without recursion
CREATE OR REPLACE FUNCTION public.get_auth_user_role()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role::text FROM public.profiles WHERE id = auth.uid();
$$;

-- Security helper to check if user is admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

-- Auto create profile on auth.users sign up trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    user_count INTEGER;
    initial_role user_role := 'employee'::user_role;
BEGIN
    -- If this is the very first user created in the system, promote them to admin!
    SELECT COUNT(*) INTO user_count FROM public.profiles;
    IF user_count = 0 THEN
        initial_role := 'admin'::user_role;
    END IF;

    INSERT INTO public.profiles (
        id,
        email,
        full_name,
        role,
        screenshot_interval,
        allow_screenshot_capture,
        allow_camera_capture
    ) VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
        initial_role,
        10,
        true,
        false
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = COALESCE(EXCLUDED.full_name, profiles.full_name),
        updated_at = NOW();

    RETURN NEW;
END;
$$;

-- Register trigger on auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Auto update timestamps trigger
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS set_profiles_updated_at ON public.profiles;
CREATE TRIGGER set_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_projects_updated_at ON public.projects;
CREATE TRIGGER set_projects_updated_at BEFORE UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_time_entries_updated_at ON public.time_entries;
CREATE TRIGGER set_time_entries_updated_at BEFORE UPDATE ON public.time_entries FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ==============================================================================
-- 6. Row-Level Security (RLS) Policies
-- ==============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_managers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.time_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_time_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.screenshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- PROFILES Policies
DROP POLICY IF EXISTS "Profiles read access" ON public.profiles;
CREATE POLICY "Profiles read access" ON public.profiles
    FOR SELECT TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Profiles update access" ON public.profiles;
CREATE POLICY "Profiles update access" ON public.profiles
    FOR UPDATE TO authenticated
    USING (auth.uid() = id OR public.is_admin());

DROP POLICY IF EXISTS "Profiles insert access" ON public.profiles;
CREATE POLICY "Profiles insert access" ON public.profiles
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = id OR public.is_admin());

-- TIME ENTRIES Policies
DROP POLICY IF EXISTS "Time entries select" ON public.time_entries;
CREATE POLICY "Time entries select" ON public.time_entries
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id OR public.is_admin());

DROP POLICY IF EXISTS "Time entries insert" ON public.time_entries;
CREATE POLICY "Time entries insert" ON public.time_entries
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id OR public.is_admin());

DROP POLICY IF EXISTS "Time entries update" ON public.time_entries;
CREATE POLICY "Time entries update" ON public.time_entries
    FOR UPDATE TO authenticated
    USING (auth.uid() = user_id OR public.is_admin());

DROP POLICY IF EXISTS "Time entries delete" ON public.time_entries;
CREATE POLICY "Time entries delete" ON public.time_entries
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id OR public.is_admin());

-- SCREENSHOTS Policies
DROP POLICY IF EXISTS "Screenshots select" ON public.screenshots;
CREATE POLICY "Screenshots select" ON public.screenshots
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id OR public.is_admin());

DROP POLICY IF EXISTS "Screenshots insert" ON public.screenshots;
CREATE POLICY "Screenshots insert" ON public.screenshots
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id OR public.is_admin());

DROP POLICY IF EXISTS "Screenshots delete" ON public.screenshots;
CREATE POLICY "Screenshots delete" ON public.screenshots
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id OR public.is_admin());

-- ACTIVITY LOGS Policies
DROP POLICY IF EXISTS "Activity logs access" ON public.activity_logs;
CREATE POLICY "Activity logs access" ON public.activity_logs
    FOR ALL TO authenticated
    USING (true);

-- ATTENDANCE Policies
DROP POLICY IF EXISTS "Attendance select" ON public.attendance;
CREATE POLICY "Attendance select" ON public.attendance
    FOR SELECT TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Attendance modify" ON public.attendance;
CREATE POLICY "Attendance modify" ON public.attendance
    FOR ALL TO authenticated
    USING (auth.uid() = user_id OR public.is_admin());

-- PROJECTS & TASKS Policies
DROP POLICY IF EXISTS "Projects read" ON public.projects;
CREATE POLICY "Projects read" ON public.projects
    FOR SELECT TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Projects modify" ON public.projects;
CREATE POLICY "Projects modify" ON public.projects
    FOR ALL TO authenticated
    USING (public.is_admin() OR auth.uid() = created_by);

DROP POLICY IF EXISTS "Tasks read" ON public.tasks;
CREATE POLICY "Tasks read" ON public.tasks
    FOR SELECT TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Tasks modify" ON public.tasks;
CREATE POLICY "Tasks modify" ON public.tasks
    FOR ALL TO authenticated
    USING (public.is_admin());

DROP POLICY IF EXISTS "Project members all" ON public.project_members;
CREATE POLICY "Project members all" ON public.project_members
    FOR ALL TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Project time entries all" ON public.project_time_entries;
CREATE POLICY "Project time entries all" ON public.project_time_entries
    FOR ALL TO authenticated
    USING (true);

-- NOTIFICATIONS Policies
DROP POLICY IF EXISTS "Notifications user policy" ON public.notifications;
CREATE POLICY "Notifications user policy" ON public.notifications
    FOR ALL TO authenticated
    USING (auth.uid() = user_id);

-- SYSTEM SETTINGS Policies
DROP POLICY IF EXISTS "System settings read" ON public.system_settings;
CREATE POLICY "System settings read" ON public.system_settings
    FOR SELECT TO authenticated
    USING (true);

DROP POLICY IF EXISTS "System settings admin" ON public.system_settings;
CREATE POLICY "System settings admin" ON public.system_settings
    FOR ALL TO authenticated
    USING (public.is_admin());

-- CLIENTS & GROUPS Policies
DROP POLICY IF EXISTS "Clients all" ON public.clients;
CREATE POLICY "Clients all" ON public.clients FOR ALL TO authenticated USING (true);

DROP POLICY IF EXISTS "Groups all" ON public.groups;
CREATE POLICY "Groups all" ON public.groups FOR ALL TO authenticated USING (true);

DROP POLICY IF EXISTS "Group members all" ON public.group_members;
CREATE POLICY "Group members all" ON public.group_members FOR ALL TO authenticated USING (true);

DROP POLICY IF EXISTS "Employee managers all" ON public.employee_managers;
CREATE POLICY "Employee managers all" ON public.employee_managers FOR ALL TO authenticated USING (true);

DROP POLICY IF EXISTS "User logs policy" ON public.user_logs;
CREATE POLICY "User logs policy" ON public.user_logs FOR ALL TO authenticated USING (auth.uid() = user_id OR public.is_admin());

-- ==============================================================================
-- 7. Seed Initial System Settings
-- ==============================================================================

INSERT INTO public.system_settings (key, value, description)
VALUES 
    ('required_tracker_version', '{"requiredVersion": "2.0.0", "minVersion": "1.0.0"}'::jsonb, 'AuraTrack desktop client version enforcement'),
    ('default_screenshot_interval', '{"interval": 10}'::jsonb, 'Default screenshot capture interval in minutes')
ON CONFLICT (key) DO NOTHING;

-- Seed Default General Project
INSERT INTO public.projects (name, description, color, status)
VALUES ('General Productivity', 'Default project for unassigned time tracking', '#06B6D4', 'active')
ON CONFLICT DO NOTHING;

-- Done!
