
-- Add app_version field to time_entries table
ALTER TABLE public.time_entries
ADD COLUMN app_version TEXT;

-- Add comment to document the field
COMMENT ON COLUMN public.time_entries.app_version IS 'Version string from package.json (e.g., "1.4.0")';
