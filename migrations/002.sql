-- Create employee_managers table to support multiple managers per employee
CREATE TABLE IF NOT EXISTS public.employee_managers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  manager_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  manager_type text NOT NULL DEFAULT 'primary', -- 'primary', 'secondary', 'hr'
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(employee_id, manager_id)
);

-- Enable RLS on employee_managers table
ALTER TABLE public.employee_managers ENABLE ROW LEVEL SECURITY;

-- Create policies for employee_managers table
CREATE POLICY "Users can view their own manager relationships"
  ON public.employee_managers
  FOR SELECT
  USING (
    employee_id = auth.uid() OR manager_id = auth.uid()
  );

CREATE POLICY "Admins can manage all manager relationships"
  ON public.employee_managers
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "HR can view all manager relationships"
  ON public.employee_managers
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'hr'
    )
  );

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS employee_managers_employee_id_idx ON public.employee_managers(employee_id);
CREATE INDEX IF NOT EXISTS employee_managers_manager_id_idx ON public.employee_managers(manager_id);
CREATE INDEX IF NOT EXISTS employee_managers_type_idx ON public.employee_managers(manager_type);

-- Create function to get all managers for an employee
CREATE OR REPLACE FUNCTION public.get_employee_managers(emp_id uuid)
RETURNS TABLE(manager_id uuid, manager_type text) AS $$
BEGIN
  RETURN QUERY
  SELECT em.manager_id, em.manager_type
  FROM public.employee_managers em
  WHERE em.employee_id = emp_id
  UNION
  SELECT p.manager_id, 'legacy'::text
  FROM public.profiles p
  WHERE p.id = emp_id AND p.manager_id IS NOT NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to check if user is a manager of employee
CREATE OR REPLACE FUNCTION public.is_manager_of_employee(manager_uuid uuid, employee_uuid uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.employee_managers em
    WHERE em.manager_id = manager_uuid AND em.employee_id = employee_uuid
    UNION
    SELECT 1 FROM public.profiles p
    WHERE p.id = employee_uuid AND p.manager_id = manager_uuid
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update screenshots policies to support dual managers
DROP POLICY IF EXISTS "Managers can view their team's screenshots" ON public.screenshots;

CREATE POLICY "Managers can view their team's screenshots"
  ON public.screenshots
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.time_entries
      JOIN public.profiles ON time_entries.user_id = profiles.id
      WHERE time_entries.id = screenshots.time_entry_id
      AND (
        -- Check if current user is a manager of the employee
        public.is_manager_of_employee(auth.uid(), profiles.id)
        OR
        -- Legacy support for manager_id field
        profiles.manager_id = auth.uid()
      )
    )
  );

-- Update time entries policies to support dual managers
DROP POLICY IF EXISTS "Managers can view their team's time entries" ON public.time_entries;

CREATE POLICY "Managers can view their team's time entries"
  ON public.time_entries
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = time_entries.user_id
      AND (
        -- Check if current user is a manager of the employee
        public.is_manager_of_employee(auth.uid(), profiles.id)
        OR
        -- Legacy support for manager_id field
        profiles.manager_id = auth.uid()
      )
    )
  );

-- Update profiles policies to support dual managers
DROP POLICY IF EXISTS "Managers can view their team's profiles" ON public.profiles;

CREATE POLICY "Managers can view their team's profiles"
  ON public.profiles
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles AS viewer
      WHERE viewer.id = auth.uid()
      AND (
        -- Check if current user is a manager of the employee
        public.is_manager_of_employee(auth.uid(), public.profiles.id)
        OR
        -- Legacy support for manager_id field
        public.profiles.manager_id = auth.uid()
      )
    )
  );

-- Create trigger to handle updated_at
CREATE TRIGGER set_timestamp_employee_managers
  BEFORE UPDATE ON public.employee_managers
  FOR EACH ROW
  EXECUTE PROCEDURE public.handle_updated_at();