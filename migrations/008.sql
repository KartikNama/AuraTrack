-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their leave request approvers" ON public.leave_approvers;
DROP POLICY IF EXISTS "Approvers can view and update their assigned requests" ON public.leave_approvers;

-- Create new policies for leave approvers
CREATE POLICY "Users can manage leave request approvers"
  ON public.leave_approvers
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.leave_requests
      WHERE leave_requests.id = leave_approvers.leave_request_id
      AND leave_requests.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.leave_requests
      WHERE leave_requests.id = leave_approvers.leave_request_id
      AND leave_requests.user_id = auth.uid()
    )
  );

CREATE POLICY "Approvers can view and update assigned requests"
  ON public.leave_approvers
  FOR ALL
  TO authenticated
  USING (
    approver_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'::public.user_role
    )
  )
  WITH CHECK (
    approver_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'::public.user_role
    )
  );

-- Update leave requests policies to ensure proper access
CREATE POLICY "Managers can update leave requests they approve"
  ON public.leave_requests
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.leave_approvers
      WHERE leave_approvers.leave_request_id = public.leave_requests.id
      AND leave_approvers.approver_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.leave_approvers
      WHERE leave_approvers.leave_request_id = public.leave_requests.id
      AND leave_approvers.approver_id = auth.uid()
    )
  );