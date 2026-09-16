-- Add screenshot and camera capture settings to profiles table
-- Default is true (enabled) for all users

ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS enable_screenshot_capture BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN IF NOT EXISTS enable_camera_capture BOOLEAN NOT NULL DEFAULT true;

-- Add comments for clarity
COMMENT ON COLUMN profiles.enable_screenshot_capture IS 'Controls whether the tracker app should capture screenshots for this user. Default: true';
COMMENT ON COLUMN profiles.enable_camera_capture IS 'Controls whether the tracker app should capture camera shots for this user. Default: true';

-- Create index for faster queries (optional but recommended)
CREATE INDEX IF NOT EXISTS idx_profiles_screenshot_capture ON profiles(enable_screenshot_capture);
CREATE INDEX IF NOT EXISTS idx_profiles_camera_capture ON profiles(enable_camera_capture);
