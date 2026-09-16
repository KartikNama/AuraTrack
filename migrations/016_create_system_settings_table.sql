-- Create system_settings table
CREATE TABLE IF NOT EXISTS public.system_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  setting_key TEXT UNIQUE NOT NULL,
  setting_value JSONB NOT NULL,
  description TEXT,
  category TEXT NOT NULL DEFAULT 'general',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default settings (using proper JSON format)
INSERT INTO public.system_settings (setting_key, setting_value, description, category) VALUES
  ('tracker_reset_hour', '"6"', 'Hour at which the tracker resets (24-hour format)', 'time_tracking'),
  ('timezone', '"Asia/Kolkata"', 'Default timezone for the system', 'general'),
  ('present_hours_threshold', '"8"', 'Minimum hours required for Present status', 'attendance'),
  ('half_day_hours_threshold', '"4"', 'Minimum hours required for Half Day status', 'attendance'),
  ('working_days_per_week', '"5"', 'Number of working days per week', 'general'),
  ('default_working_hours_start', '"09:00"', 'Default start time for working hours', 'general'),
  ('default_working_hours_end', '"18:00"', 'Default end time for working hours', 'general')
ON CONFLICT (setting_key) DO NOTHING;

-- Enable RLS
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

-- Policy: Only admins can read and write
CREATE POLICY "Admins can manage system settings"
  ON public.system_settings
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_system_settings_updated_at
  BEFORE UPDATE ON public.system_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();