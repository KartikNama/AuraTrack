-- Create notification type enum
CREATE TYPE public.notification_type AS ENUM (
  'leave_request',
  'leave_approved',
  'leave_rejected',
  'time_tracking',
  'system'
);

-- Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  title text NOT NULL,
  message text NOT NULL,
  type public.notification_type NOT NULL,
  read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Create notification policies
CREATE POLICY "Users can view their own notifications"
  ON public.notifications
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "System can create notifications"
  ON public.notifications
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Create function to handle leave request notifications
CREATE OR REPLACE FUNCTION public.handle_leave_request_notification()
RETURNS TRIGGER AS $$
DECLARE
  approver_record RECORD;
  requester_name text;
BEGIN
  -- Get requester's name
  SELECT full_name INTO requester_name
  FROM public.profiles
  WHERE id = NEW.user_id;

  -- For new leave requests, notify approvers
  IF TG_OP = 'INSERT' THEN
    FOR approver_record IN
      SELECT approver_id
      FROM public.leave_approvers
      WHERE leave_request_id = NEW.id
    LOOP
      INSERT INTO public.notifications (user_id, title, message, type)
      VALUES (
        approver_record.approver_id,
        'New Leave Request',
        requester_name || ' has submitted a leave request for your approval',
        'leave_request'
      );
    END LOOP;
  END IF;

  -- For status updates, notify the requester
  IF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
    INSERT INTO public.notifications (user_id, title, message, type)
    VALUES (
      NEW.user_id,
      CASE 
        WHEN NEW.status = 'approved' THEN 'Leave Request Approved'
        WHEN NEW.status = 'rejected' THEN 'Leave Request Rejected'
        ELSE 'Leave Request Updated'
      END,
      CASE 
        WHEN NEW.status = 'approved' THEN 'Your leave request has been approved'
        WHEN NEW.status = 'rejected' THEN 'Your leave request has been rejected'
        ELSE 'Your leave request status has been updated'
      END,
      CASE 
        WHEN NEW.status = 'approved' THEN 'leave_approved'::public.notification_type
        WHEN NEW.status = 'rejected' THEN 'leave_rejected'::public.notification_type
        ELSE 'leave_request'::public.notification_type
      END
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for leave request notifications
CREATE TRIGGER leave_request_notification
  AFTER INSERT OR UPDATE ON public.leave_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_leave_request_notification();

-- Create function to update leave request status based on approvers
CREATE OR REPLACE FUNCTION public.update_leave_request_status()
RETURNS TRIGGER AS $$
DECLARE
  all_approved boolean;
  any_rejected boolean;
BEGIN
  -- Get all approvers status for this leave request
  SELECT 
    bool_and(status = 'approved') as all_approved,
    bool_or(status = 'rejected') as any_rejected
  INTO all_approved, any_rejected
  FROM public.leave_approvers
  WHERE leave_request_id = NEW.leave_request_id;

  -- Update leave request status
  IF any_rejected THEN
    UPDATE public.leave_requests
    SET status = 'rejected'::public.leave_status
    WHERE id = NEW.leave_request_id;
  ELSIF all_approved THEN
    UPDATE public.leave_requests
    SET status = 'approved'::public.leave_status
    WHERE id = NEW.leave_request_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updating leave request status
CREATE TRIGGER update_leave_status
  AFTER UPDATE OF status ON public.leave_approvers
  FOR EACH ROW
  EXECUTE FUNCTION public.update_leave_request_status();