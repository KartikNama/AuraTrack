-- Create storage bucket if not exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('screenshots', 'screenshots', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for screenshots bucket
CREATE POLICY "Users can upload their own screenshots"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'screenshots' AND
  (auth.uid()::text = SPLIT_PART(name, '/', 1))
);

CREATE POLICY "Users can view their own screenshots"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'screenshots' AND
  (
    -- User's own screenshots
    auth.uid()::text = SPLIT_PART(name, '/', 1)
    OR
    -- Manager viewing team screenshots
    EXISTS (
      SELECT 1 FROM public.profiles manager
      WHERE manager.id = auth.uid()
      AND manager.role = 'manager'::public.user_role
      AND (SPLIT_PART(storage.objects.name, '/', 1))::uuid IN (
        SELECT id FROM public.profiles WHERE manager_id = manager.id
      )
    )
    OR
    -- Admin can view all
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND role = 'admin'::public.user_role
    )
  )
);

-- Fix admin access to profiles
DROP POLICY IF EXISTS "Admin full access to profiles" ON public.profiles;
CREATE POLICY "Admin full access to profiles"
ON public.profiles
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND role = 'admin'::public.user_role
  )
)
WITH CHECK (true);

-- Fix admin access to time entries
DROP POLICY IF EXISTS "Admin full access to time entries" ON public.time_entries;
CREATE POLICY "Admin full access to time entries"
ON public.time_entries
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND role = 'admin'::public.user_role
  )
)
WITH CHECK (true);

-- Fix admin access to screenshots table
DROP POLICY IF EXISTS "Admin full access to screenshots table" ON public.screenshots;
CREATE POLICY "Admin full access to screenshots table"
ON public.screenshots
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND role = 'admin'::public.user_role
  )
)
WITH CHECK (true);