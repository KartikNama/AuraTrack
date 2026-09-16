-- 1. Create role enum
CREATE TYPE public.user_role AS ENUM ('employee', 'manager', 'admin', 'hr');

-- 2. Create profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text NOT NULL,
  role public.user_role NOT NULL DEFAULT 'employee',
  manager_id uuid REFERENCES public.profiles(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 3. Create time entries table
CREATE TABLE IF NOT EXISTS public.time_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  start_time timestamptz NOT NULL DEFAULT now(),
  end_time timestamptz,
  description text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 4. Create screenshots table
CREATE TABLE IF NOT EXISTS public.screenshots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  time_entry_id uuid REFERENCES public.time_entries(id) ON DELETE CASCADE NOT NULL,
  storage_path text NOT NULL,
  taken_at timestamptz DEFAULT now(),
  type text NOT NULL, -- 'screen' or 'webcam'
  created_at timestamptz DEFAULT now()
);

-- 5. Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.time_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.screenshots ENABLE ROW LEVEL SECURITY;

-- 6. Profiles policies
CREATE POLICY "Users can view their own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Managers can view their team's profiles"
  ON public.profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles AS viewer 
      WHERE viewer.id = auth.uid() 
      AND (viewer.role = 'manager' AND public.profiles.manager_id = viewer.id)
    )
  );

CREATE POLICY "Admins can view all profiles"
  ON public.profiles FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

-- 7. Time entries policies
CREATE POLICY "Users can CRUD their own time entries"
  ON public.time_entries FOR ALL
  USING (auth.uid() = user_id);

CREATE POLICY "Managers can view their team's time entries"
  ON public.time_entries FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles AS viewer 
      WHERE viewer.id = auth.uid() 
      AND viewer.role = 'manager'
      AND public.time_entries.user_id IN (
        SELECT id FROM public.profiles WHERE manager_id = viewer.id
      )
    )
  );

CREATE POLICY "Admins can view all time entries"
  ON public.time_entries FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

-- 8. Screenshots policies
CREATE POLICY "Users can view their own screenshots"
  ON public.screenshots FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.time_entries
      WHERE time_entries.id = screenshots.time_entry_id
      AND time_entries.user_id = auth.uid()
    )
  );

CREATE POLICY "Managers can view their team's screenshots"
  ON public.screenshots FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.time_entries
      JOIN public.profiles ON time_entries.user_id = profiles.id
      JOIN public.profiles manager ON profiles.manager_id = manager.id
      WHERE time_entries.id = screenshots.time_entry_id
      AND manager.id = auth.uid()
      AND manager.role = 'manager'
    )
  );

CREATE POLICY "Admins can view all screenshots"
  ON public.screenshots FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

-- 9. Functions & Triggers
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_timestamp_profiles
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER set_timestamp_time_entries
  BEFORE UPDATE ON public.time_entries
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();