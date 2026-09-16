-- Update user_role enum to include new roles
-- Note: ALTER TYPE ... ADD VALUE cannot be executed in a transaction block in some Postgres environments.
ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'hr';
ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'accountant';

-- Add duration column to time_entries if not exists
ALTER TABLE public.time_entries
ADD COLUMN IF NOT EXISTS duration double precision;

-- Create function to calculate duration
CREATE OR REPLACE FUNCTION public.calculate_time_entry_duration()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.end_time IS NOT NULL THEN
    NEW.duration = EXTRACT(EPOCH FROM (NEW.end_time - NEW.start_time)) / 3600.0;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically calculate duration
DROP TRIGGER IF EXISTS update_time_entry_duration ON public.time_entries;
CREATE TRIGGER update_time_entry_duration
  BEFORE INSERT OR UPDATE ON public.time_entries
  FOR EACH ROW
  EXECUTE FUNCTION public.calculate_time_entry_duration();

-- Create function to adjust date for 5 AM cutoff
CREATE OR REPLACE FUNCTION public.adjust_date_for_cutoff(timestamp with time zone)
RETURNS date AS $$
BEGIN
  RETURN date(
    CASE 
      WHEN EXTRACT(HOUR FROM $1) < 5 THEN
        $1 - interval '1 day'
      ELSE
        $1
    END
  );
END;
$$ LANGUAGE plpgsql;