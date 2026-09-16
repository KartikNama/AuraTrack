-- Drop all existing policies on project_members to fix recursion
DROP POLICY IF EXISTS "Admins can manage all project members" ON public.project_members;
DROP POLICY IF EXISTS "Managers can manage members of their projects" ON public.project_members;
DROP POLICY IF EXISTS "Everyone can view project members" ON public.project_members;
DROP POLICY IF EXISTS "Users can view their own project memberships" ON public.project_members;

-- Create simpler policies that don't cause recursion
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

-- Managers can manage members for projects they created
-- Use a direct check without referencing projects table in a way that causes recursion
CREATE POLICY "Managers can manage members of their projects"
  ON public.project_members
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
      AND p.role = 'manager'
      AND EXISTS (
        SELECT 1 FROM public.projects pr
        WHERE pr.id = project_members.project_id
        AND pr.created_by = auth.uid()
      )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
      AND p.role = 'manager'
      AND EXISTS (
        SELECT 1 FROM public.projects pr
        WHERE pr.id = project_members.project_id
        AND pr.created_by = auth.uid()
      )
    )
  );

-- Everyone can view project members
CREATE POLICY "Everyone can view project members"
  ON public.project_members
  FOR SELECT
  USING (true);

-- Users can view their own project memberships
CREATE POLICY "Users can view their own project memberships"
  ON public.project_members
  FOR SELECT
  USING (user_id = auth.uid());