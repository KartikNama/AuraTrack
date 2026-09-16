-- Drop existing policies
DROP POLICY IF EXISTS "Admins can manage all project members" ON public.project_members;
DROP POLICY IF EXISTS "Managers can view project members" ON public.project_members;
DROP POLICY IF EXISTS "Users can view their own project memberships" ON public.project_members;

-- Create comprehensive policies for project_members
-- Admins can do everything
CREATE POLICY "Admins can manage all project members"
  ON public.project_members
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

-- Managers can manage project members for projects they created
CREATE POLICY "Managers can manage members of their projects"
  ON public.project_members
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'manager'
      AND EXISTS (
        SELECT 1 FROM public.projects
        WHERE projects.id = project_members.project_id
        AND projects.created_by = auth.uid()
      )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'manager'
      AND EXISTS (
        SELECT 1 FROM public.projects
        WHERE projects.id = project_members.project_id
        AND projects.created_by = auth.uid()
      )
    )
  );

-- Everyone can view project members (for seeing who's on a project)
CREATE POLICY "Everyone can view project members"
  ON public.project_members
  FOR SELECT
  USING (true);

-- Users can view their own project memberships
CREATE POLICY "Users can view their own project memberships"
  ON public.project_members
  FOR SELECT
  USING (user_id = auth.uid());