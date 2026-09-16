-- Add tracker version management settings to system_settings table
-- These settings control the required version for the Electron tracker app

-- Insert default tracker version settings if they don't exist
INSERT INTO system_settings (setting_key, setting_value, category, description, updated_at)
VALUES 
  (
    'tracker_required_version',
    '"1.0.0"',
    'tracker',
    'Required version of the Electron tracker app (semantic versioning format: MAJOR.MINOR.PATCH). Apps with versions that do not match this will be blocked from tracking.',
    NOW()
  ),
  (
    'tracker_update_url',
    '""',
    'tracker',
    'URL where users can download the latest version of the tracker app. Leave empty if not applicable.',
    NOW()
  ),
  (
    'tracker_force_update',
    'false',
    'tracker',
    'If true, all tracker apps must update immediately. If false, apps can continue with a warning.',
    NOW()
  )
ON CONFLICT (setting_key) DO NOTHING;

-- Add comment to system_settings table for documentation
COMMENT ON TABLE system_settings IS 'System-wide configuration settings. Includes tracker version management.';
