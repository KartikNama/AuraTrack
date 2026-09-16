-- Drop existing policies if they exist
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Allow all for clients" ON public.clients;
  DROP POLICY IF EXISTS "Allow all for projects" ON public.projects;
  DROP POLICY IF EXISTS "Allow all for project_members" ON public.project_members;
  DROP POLICY IF EXISTS "Allow all for attendance" ON public.attendance;
  DROP POLICY IF EXISTS "Allow all for project_time_entries" ON public.project_time_entries;
  DROP POLICY IF EXISTS "Admins can manage all clients" ON public.clients;
  DROP POLICY IF EXISTS "Managers can view all clients" ON public.clients;
  DROP POLICY IF EXISTS "Admins can manage all projects" ON public.projects;
  DROP POLICY IF EXISTS "Managers can view all projects" ON public.projects;
  DROP POLICY IF EXISTS "Employees can view projects they are members of" ON public.projects;
  DROP POLICY IF EXISTS "Admins can manage all project members" ON public.project_members;
  DROP POLICY IF EXISTS "Managers can view project members" ON public.project_members;
  DROP POLICY IF EXISTS "Users can view their own project memberships" ON public.project_members;
  DROP POLICY IF EXISTS "Admins can manage all attendance" ON public.attendance;
  DROP POLICY IF EXISTS "Managers can view their team attendance" ON public.attendance;
  DROP POLICY IF EXISTS "Users can view their own attendance" ON public.attendance;
  DROP POLICY IF EXISTS "Users can insert their own attendance" ON public.attendance;
  DROP POLICY IF EXISTS "Users can update their own attendance" ON public.attendance;
  DROP POLICY IF EXISTS "Admins can manage all project time entries" ON public.project_time_entries;
  DROP POLICY IF EXISTS "Managers can view team project time entries" ON public.project_time_entries;
  DROP POLICY IF EXISTS "Users can view their own project time entries" ON public.project_time_entries;
  DROP POLICY IF EXISTS "Admins can view all screenshots" ON public.screenshots;
  DROP POLICY IF EXISTS "Managers can view team screenshots" ON public.screenshots;
  DROP POLICY IF EXISTS "Users can view their own screenshots" ON public.screenshots;
  DROP POLICY IF EXISTS "Users can view their own time entries" ON public.time_entries;
  DROP POLICY IF EXISTS "Managers can view team time entries" ON public.time_entries;
  DROP POLICY IF EXISTS "Admins can view all time entries" ON public.time_entries;
END $$;

-- Helper function to check if user is admin
CREATE OR REPLACE FUNCTION public.is_admin(user_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = user_id AND role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- Helper function to check if user is manager
CREATE OR REPLACE FUNCTION public.is_manager(user_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = user_id AND role IN ('manager', 'admin', 'hr')
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- Helper function to check if user manages employee
CREATE OR REPLACE FUNCTION public.manages_employee(manager_id UUID, employee_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.employee_managers
    WHERE manager_id = manages_employee.manager_id
    AND employee_id = manages_employee.employee_id
  ) OR EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = employee_id AND manager_id = manages_employee.manager_id
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- Clients policies
CREATE POLICY "Admins can manage all clients" ON public.clients
  FOR ALL USING (public.is_admin(auth.uid()));

CREATE POLICY "Managers can view all clients" ON public.clients
  FOR SELECT USING (public.is_manager(auth.uid()));

-- Projects policies
CREATE POLICY "Admins can manage all projects" ON public.projects
  FOR ALL USING (public.is_admin(auth.uid()));

CREATE POLICY "Managers can view all projects" ON public.projects
  FOR SELECT USING (public.is_manager(auth.uid()));

CREATE POLICY "Employees can view projects they are members of" ON public.projects
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.project_members
      WHERE project_id = projects.id
      AND user_id = auth.uid()
    )
  );

-- Project members policies
CREATE POLICY "Admins can manage all project members" ON public.project_members
  FOR ALL USING (public.is_admin(auth.uid()));

CREATE POLICY "Managers can view project members" ON public.project_members
  FOR SELECT USING (public.is_manager(auth.uid()));

CREATE POLICY "Users can view their own project memberships" ON public.project_members
  FOR SELECT USING (user_id = auth.uid());

-- Attendance policies
CREATE POLICY "Admins can manage all attendance" ON public.attendance
  FOR ALL USING (public.is_admin(auth.uid()));

CREATE POLICY "Managers can view their team attendance" ON public.attendance
  FOR SELECT USING (
    public.is_manager(auth.uid()) AND (
      public.manages_employee(auth.uid(), user_id) OR user_id = auth.uid()
    )
  );

CREATE POLICY "Users can view their own attendance" ON public.attendance
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own attendance" ON public.attendance
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own attendance" ON public.attendance
  FOR UPDATE USING (user_id = auth.uid());

-- Project time entries policies
CREATE POLICY "Admins can manage all project time entries" ON public.project_time_entries
  FOR ALL USING (public.is_admin(auth.uid()));

CREATE POLICY "Managers can view team project time entries" ON public.project_time_entries
  FOR SELECT USING (
    public.is_manager(auth.uid()) AND EXISTS (
      SELECT 1 FROM public.time_entries te
      WHERE te.id = project_time_entries.time_entry_id
      AND (public.manages_employee(auth.uid(), te.user_id) OR te.user_id = auth.uid())
    )
  );

CREATE POLICY "Users can view their own project time entries" ON public.project_time_entries
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.time_entries te
      WHERE te.id = project_time_entries.time_entry_id
      AND te.user_id = auth.uid()
    )
  );

-- Screenshots policies
CREATE POLICY "Admins can view all screenshots" ON public.screenshots
  FOR SELECT USING (
    public.is_admin(auth.uid()) OR EXISTS (
      SELECT 1 FROM public.time_entries te
      WHERE te.id = screenshots.time_entry_id
      AND te.user_id = auth.uid()
    )
  );

CREATE POLICY "Managers can view team screenshots" ON public.screenshots
  FOR SELECT USING (
    public.is_manager(auth.uid()) AND EXISTS (
      SELECT 1 FROM public.time_entries te
      WHERE te.id = screenshots.time_entry_id
      AND (public.manages_employee(auth.uid(), te.user_id) OR te.user_id = auth.uid())
    )
  );

CREATE POLICY "Users can view their own screenshots" ON public.screenshots
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.time_entries te
      WHERE te.id = screenshots.time_entry_id
      AND te.user_id = auth.uid()
    )
  );

-- Time entries policies
CREATE POLICY "Users can view their own time entries" ON public.time_entries
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Managers can view team time entries" ON public.time_entries
  FOR SELECT USING (
    public.is_manager(auth.uid()) AND (
      public.manages_employee(auth.uid(), user_id) OR user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can view all time entries" ON public.time_entries
  FOR SELECT USING (public.is_admin(auth.uid()));