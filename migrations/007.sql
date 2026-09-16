-- Create leave status enum
CREATE TYPE public.leave_status AS ENUM ('pending', 'approved', 'rejected');

-- Create leave types table
CREATE TABLE IF NOT EXISTS public.leave_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  color text,
  created_at timestamptz DEFAULT now()
);

-- Create leave requests table
CREATE TABLE IF NOT EXISTS public.leave_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  start_date date NOT NULL,
  end_date date NOT NULL,
  type_id uuid REFERENCES public.leave_types(id) ON DELETE CASCADE NOT NULL,
  reason text NOT NULL,
  status public.leave_status DEFAULT 'pending',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create leave approvers table
CREATE TABLE IF NOT EXISTS public.leave_approvers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  leave_request_id uuid REFERENCES public.leave_requests(id) ON DELETE CASCADE NOT NULL,
  approver_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  status public.leave_status DEFAULT 'pending',
  comment text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.leave_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_approvers ENABLE ROW LEVEL SECURITY;

-- Leave types policies
CREATE POLICY "Everyone can view leave types"
  ON public.leave_types
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Only admins can manage leave types"
  ON public.leave_types
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'::public.user_role
    )
  );

-- Leave requests policies
CREATE POLICY "Users can view their own leave requests"
  ON public.leave_requests
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own leave requests"
  ON public.leave_requests
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their pending leave requests"
  ON public.leave_requests
  FOR UPDATE
  TO authenticated
  USING (
    auth.uid() = user_id
    AND status = 'pending'::public.leave_status
  );

CREATE POLICY "Managers can view their team's leave requests"
  ON public.leave_requests
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = public.leave_requests.user_id
      AND profiles.manager_id = auth.uid()
    )
  );

CREATE POLICY "Admins can view all leave requests"
  ON public.leave_requests
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'::public.user_role
    )
  );

-- Leave approvers policies
CREATE POLICY "Users can view their leave request approvers"
  ON public.leave_approvers
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.leave_requests
      WHERE public.leave_requests.id = public.leave_approvers.leave_request_id
      AND public.leave_requests.user_id = auth.uid()
    )
  );

CREATE POLICY "Approvers can view and update their assigned requests"
  ON public.leave_approvers
  FOR ALL
  TO authenticated
  USING (auth.uid() = approver_id);

-- Insert default leave types
INSERT INTO public.leave_types (name, description, color) VALUES
  ('Annual Leave', 'Regular paid time off', '#10B981'),
  ('Sick Leave', 'Leave for medical reasons', '#EF4444'),
  ('Personal Leave', 'Leave for personal matters', '#F59E0B'),
  ('Bereavement Leave', 'Leave for family loss', '#6B7280'),
  ('Study Leave', 'Leave for educational purposes', '#8B5CF6')
ON CONFLICT DO NOTHING;

-- Trigger for updated_at (using existing handle_updated_at function)
CREATE TRIGGER set_timestamp_leave_requests
  BEFORE UPDATE ON public.leave_requests
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER set_timestamp_leave_approvers
  BEFORE UPDATE ON public.leave_approvers
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();