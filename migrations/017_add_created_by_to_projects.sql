-- Add created_by field to projects table
ALTER TABLE public.projects 
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES public.profiles(id);

-- Update existing projects to set created_by (if any exist, set to first admin or null)
UPDATE public.projects 
SET created_by = (SELECT id FROM public.profiles WHERE role = 'admin' LIMIT 1)
WHERE created_by IS NULL;