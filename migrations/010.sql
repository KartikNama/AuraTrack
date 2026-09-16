-- Create function to validate leave request dates
CREATE OR REPLACE FUNCTION public.validate_leave_request()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if end date is after start date
  IF NEW.end_date < NEW.start_date THEN
    RAISE EXCEPTION 'End date must be after start date';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for leave request validation
CREATE TRIGGER validate_leave_request_trigger
  BEFORE INSERT OR UPDATE ON public.leave_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_leave_request();

-- Create function to update leave request status based on approvers
CREATE OR REPLACE FUNCTION public.update_leave_request_status()
RETURNS TRIGGER AS $$
DECLARE
  all_approved BOOLEAN;
  any_rejected BOOLEAN;
  total_approvers INTEGER;
  responded_approvers INTEGER;
BEGIN
  -- Get approvers status counts
  SELECT 
    COUNT(*) = COUNT(CASE WHEN status = 'approved' THEN 1 END),
    COUNT(CASE WHEN status = 'rejected' THEN 1 END) > 0,
    COUNT(*),
    COUNT(CASE WHEN status != 'pending' THEN 1 END)
  INTO all_approved, any_rejected, total_approvers, responded_approvers
  FROM public.leave_approvers
  WHERE leave_request_id = NEW.leave_request_id;

  -- Update leave request status if all have responded
  IF responded_approvers = total_approvers THEN
    UPDATE public.leave_requests
    SET status = CASE 
      WHEN any_rejected THEN 'rejected'::public.leave_status
      WHEN all_approved THEN 'approved'::public.leave_status
      ELSE 'pending'::public.leave_status
    END
    WHERE id = NEW.leave_request_id;

    -- Create notification for the leave request owner
    INSERT INTO public.notifications (
      user_id,
      title,
      message,
      type
    )
    SELECT 
      lr.user_id,
      CASE 
        WHEN any_rejected THEN 'Leave Request Rejected'
        WHEN all_approved THEN 'Leave Request Approved'
        ELSE 'Leave Request Updated'
      END,
      CASE 
        WHEN any_rejected THEN 'Your leave request has been rejected'
        WHEN all_approved THEN 'Your leave request has been approved'
        ELSE 'Your leave request status has been updated'
      END,
      CASE 
        WHEN any_rejected THEN 'leave_rejected'::public.notification_type
        WHEN all_approved THEN 'leave_approved'::public.notification_type
        ELSE 'leave_request'::public.notification_type
      END
    FROM public.leave_requests lr
    WHERE lr.id = NEW.leave_request_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS update_leave_status ON public.leave_approvers;

-- Create new trigger for updating leave request status
CREATE TRIGGER update_leave_status
  AFTER UPDATE OF status ON public.leave_approvers
  FOR EACH ROW
  EXECUTE FUNCTION public.update_leave_request_status();

-- Fix leave approvers policies
DROP POLICY IF EXISTS "Users can manage leave request approvers" ON public.leave_approvers;
DROP POLICY IF EXISTS "Approvers can view and update assigned requests" ON public.leave_approvers;
DROP POLICY IF EXISTS "Users can view their leave request approvers" ON public.leave_approvers;

-- Create new policies for leave approvers
CREATE POLICY "Users can view their leave request approvers"
  ON public.leave_approvers
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.leave_requests
      WHERE leave_requests.id = leave_approvers.leave_request_id
      AND (
        leave_requests.user_id = auth.uid()
        OR
        leave_approvers.approver_id = auth.uid()
        OR
        EXISTS (
          SELECT 1 FROM public.profiles
          WHERE profiles.id = auth.uid()
          AND profiles.role = 'admin'::public.user_role
        )
      )
    )
  );

CREATE POLICY "Users can create leave request approvers"
  ON public.leave_approvers
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.leave_requests
      WHERE leave_requests.id = leave_request_id
      AND leave_requests.user_id = auth.uid()
    )
  );

CREATE POLICY "Approvers can update their decisions"
  ON public.leave_approvers
  FOR UPDATE
  TO authenticated
  USING (approver_id = auth.uid())
  WITH CHECK (
    approver_id = auth.uid()
    AND (
      SELECT status FROM public.leave_requests
      WHERE id = leave_request_id
    ) = 'pending'::public.leave_status
  );