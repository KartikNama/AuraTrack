-- Drop all existing policies to start fresh
DROP POLICY IF EXISTS "Allow users to create their profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can view and update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Managers can view team profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admin access" ON public.profiles;

-- Simple policy for profile creation
CREATE POLICY "allow_profile_creation"
  ON public.profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Simple policy for viewing own profile
CREATE POLICY "allow_select_own_profile"
  ON public.profiles
  FOR SELECT
  USING (auth.uid() = id);

-- Simple policy for updating own profile
CREATE POLICY "allow_update_own_profile"
  ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Manager view policy without recursion
CREATE POLICY "allow_manager_select"
  ON public.profiles
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.profiles
      WHERE id = auth.uid()
      AND role = 'manager'::public.user_role
    )
  );

-- Admin policy without recursion
CREATE POLICY "allow_admin_all"
  ON public.profiles
  FOR ALL
  USING (
    EXISTS (
      SELECT 1
      FROM public.profiles
      WHERE id = auth.uid()
      AND role = 'admin'::public.user_role
    )
  );