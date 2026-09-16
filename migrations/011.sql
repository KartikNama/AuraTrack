-- Add team field to profiles table
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS team text;

-- Update RLS policies to include team field access
-- Note: Dropping existing update policy first to prevent conflicts if it exists
DROP POLICY IF EXISTS "Users can update their own team" ON public.profiles;

CREATE POLICY "Users can update their own team"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Add force_password_change column
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS force_password_change boolean DEFAULT true;

-- Add policy for updating force_password_change status
-- Note: Dropping existing policy if it exists to ensure a clean application
DROP POLICY IF EXISTS "Users can update their own force_password_change status" ON public.profiles;

CREATE POLICY "Users can update their own force_password_change status"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);