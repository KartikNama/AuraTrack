-- Create tasks table
CREATE TABLE IF NOT EXISTS public.tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  category TEXT DEFAULT 'custom',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default tasks
INSERT INTO public.tasks (name, category) VALUES
  ('Development', 'default'),
  ('QA', 'default'),
  ('SEO', 'default'),
  ('Marketing', 'default'),
  ('Project Management', 'default')
ON CONFLICT (name) DO NOTHING;

-- Add task_id to projects table
ALTER TABLE public.projects 
ADD COLUMN IF NOT EXISTS task_id UUID REFERENCES public.tasks(id);

-- Enable RLS on tasks
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

-- Policy: Everyone can read tasks
CREATE POLICY "Everyone can read tasks"
  ON public.tasks
  FOR SELECT
  USING (true);

-- Policy: Only admins and managers can insert tasks
CREATE POLICY "Admins and managers can create tasks"
  ON public.tasks
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'manager')
    )
  );

-- Policy: Only admins and managers can update tasks
CREATE POLICY "Admins and managers can update tasks"
  ON public.tasks
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'manager')
    )
  );

-- Create updated_at trigger for tasks
CREATE TRIGGER update_tasks_updated_at
  BEFORE UPDATE ON public.tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();