-- Create user_logs table for tracking user activities
CREATE TABLE IF NOT EXISTS user_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  log_type TEXT NOT NULL,
  log_message TEXT NOT NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  ip_address TEXT,
  user_agent TEXT,
  device_info TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create index on user_id for faster queries
CREATE INDEX IF NOT EXISTS idx_user_logs_user_id ON user_logs(user_id);

-- Create index on log_type for filtering
CREATE INDEX IF NOT EXISTS idx_user_logs_log_type ON user_logs(log_type);

-- Create index on created_at for date filtering
CREATE INDEX IF NOT EXISTS idx_user_logs_created_at ON user_logs(created_at);

-- Create composite index for common queries (user + date)
CREATE INDEX IF NOT EXISTS idx_user_logs_user_date ON user_logs(user_id, created_at DESC);

-- Add comments
COMMENT ON TABLE user_logs IS 'Stores activity logs for all users, visible only to admins';
COMMENT ON COLUMN user_logs.log_type IS 'Type of log: tracker_started, tracker_stopped, inactivity_detected, continue_clicked, stop_clicked, login, logout, app_login, web_login, time_reduced, etc.';
COMMENT ON COLUMN user_logs.log_message IS 'Human-readable log message';
COMMENT ON COLUMN user_logs.metadata IS 'Additional structured data about the event (JSON)';
COMMENT ON COLUMN user_logs.ip_address IS 'IP address of the user when event occurred';
COMMENT ON COLUMN user_logs.user_agent IS 'User agent string (for web)';
COMMENT ON COLUMN user_logs.device_info IS 'Device information (for Electron app)';

-- Enable RLS
ALTER TABLE user_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Only admins can read logs
CREATE POLICY "Only admins can view user logs"
  ON user_logs
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- RLS Policy: Users can insert their own logs (for Electron app and web)
CREATE POLICY "Users can insert their own logs"
  ON user_logs
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Only admins can delete logs
CREATE POLICY "Only admins can delete user logs"
  ON user_logs
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );
