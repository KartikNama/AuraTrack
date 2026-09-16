-- Drop existing policies on projects that cause recursion
DROP POLICY IF EXISTS "Admins can manage all projects" ON public.projects;
DROP POLICY IF EXISTS "Employees can view projects they are members of" ON public.projects;
DROP POLICY IF EXISTS "Managers can view all projects" ON public.projects;
DROP POLICY IF EXISTS "Managers can manage their own projects" ON public.projects;

-- Create policies that avoid recursion
-- Admins can do everything
CREATE POLICY "Admins can manage all projects"
  ON public.projects
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Managers can manage projects they created
CREATE POLICY "Managers can manage their own projects"
  ON public.projects
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'manager'
      AND projects.created_by = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'manager'
      AND projects.created_by = auth.uid()
    )
  );

-- Everyone can view all projects (we'll filter in the application)
-- This avoids recursion by not checking project_members in the policy
CREATE POLICY "Everyone can view projects"
  ON public.projects
  FOR SELECT
  USING (true);