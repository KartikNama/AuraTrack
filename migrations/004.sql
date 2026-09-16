-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Managers can view their team's profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admin full access" ON public.profiles;

-- Create new policies
CREATE POLICY "Allow users to create their profile"
  ON public.profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can view and update own profile"
  ON public.profiles
  FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Managers can view team profiles"
  ON public.profiles
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM auth.users
      WHERE auth.users.id = auth.uid()
      AND auth.users.id IN (
        SELECT id FROM public.profiles WHERE role = 'manager'::public.user_role
      )
    )
    AND manager_id IN (
      SELECT id FROM public.profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Admin access"
  ON public.profiles
  FOR ALL
  USING (
    EXISTS (
      SELECT 1
      FROM auth.users
      WHERE auth.users.id = auth.uid()
      AND auth.users.id IN (
        SELECT id FROM public.profiles WHERE role = 'admin'::public.user_role
      )
    )
  );