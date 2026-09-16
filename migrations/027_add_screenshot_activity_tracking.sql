-- ============================================
-- SCREENSHOT ACTIVITY TRACKING TABLE
-- ============================================
-- Stores granular activity data for each screenshot interval
-- This tracks mouse, keyboard, and browsing activity during screenshot capture

CREATE TABLE IF NOT EXISTS screenshot_activity (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    screenshot_id UUID NOT NULL REFERENCES screenshots(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
    time_entry_id UUID REFERENCES time_entries(id) ON DELETE CASCADE,
    
    -- Interval timing
    interval_start_time TIMESTAMPTZ NOT NULL,
    interval_end_time TIMESTAMPTZ NOT NULL,
    interval_duration_seconds INTEGER NOT NULL, -- Duration of the interval in seconds
    
    -- Usage percentages
    mouse_usage_percentage DECIMAL(5,2) NOT NULL DEFAULT 0, -- Active mouse time / interval duration
    keyboard_usage_percentage DECIMAL(5,2) NOT NULL DEFAULT 0, -- Active typing time / interval duration
    
    -- Mouse activity details (JSON)
    mouse_activity_details JSONB NOT NULL DEFAULT '{}',
    -- Structure:
    -- {
    --   "total_clicks": 0,
    --   "click_coordinates": [{"x": 100, "y": 200, "timestamp": "2024-01-18T10:00:00Z"}],
    --   "movement_duration_ms": 0,
    --   "scroll_events": [{"direction": "down", "timestamp": "2024-01-18T10:00:00Z"}],
    --   "screen_resolution": {"width": 1920, "height": 1080},
    --   "active_time_ms": 0
    -- }
    
    -- Keyboard activity details (JSON)
    keyboard_activity_details JSONB NOT NULL DEFAULT '{}',
    -- Structure:
    -- {
    --   "total_keystrokes": 0,
    --   "key_presses": [{"key_code": "KeyA", "timestamp": "2024-01-18T10:00:00Z", "is_sensitive": false}],
    --   "active_time_ms": 0,
    --   "key_frequency": {"KeyA": 5, "KeyB": 3}
    -- }
    
    -- Suspicious activity flags
    suspicious_activity_flags TEXT[] DEFAULT ARRAY[]::TEXT[],
    -- Possible values:
    -- "repetitive_clicks", "continuous_micro_movements", "repetitive_keys",
    -- "inactivity_bypass_attempt", "artificial_activity_pattern"
    
    -- Browsing/app activity
    visited_websites JSONB DEFAULT '[]',
    -- Structure:
    -- [{"url": "example.com", "domain": "example.com", "duration_seconds": 60, "start_time": "2024-01-18T10:00:00Z"}]
    
    active_applications JSONB DEFAULT '[]',
    -- Structure:
    -- [{"name": "Chrome", "duration_seconds": 60, "start_time": "2024-01-18T10:00:00Z"}]
    
    -- Device and app info
    device_os TEXT,
    app_version TEXT,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_screenshot_activity_screenshot_id ON screenshot_activity(screenshot_id);
CREATE INDEX IF NOT EXISTS idx_screenshot_activity_user_id ON screenshot_activity(user_id);
CREATE INDEX IF NOT EXISTS idx_screenshot_activity_time_entry_id ON screenshot_activity(time_entry_id);
CREATE INDEX IF NOT EXISTS idx_screenshot_activity_interval_start ON screenshot_activity(interval_start_time);
CREATE INDEX IF NOT EXISTS idx_screenshot_activity_created_at ON screenshot_activity(created_at);

-- Enable Row Level Security
ALTER TABLE screenshot_activity ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only access their own activity data
CREATE POLICY "Users can view own screenshot activity" ON screenshot_activity
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert own screenshot activity" ON screenshot_activity
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own screenshot activity" ON screenshot_activity
    FOR UPDATE USING (user_id = auth.uid());

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_screenshot_activity_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER trigger_update_screenshot_activity_updated_at
    BEFORE UPDATE ON screenshot_activity
    FOR EACH ROW
    EXECUTE FUNCTION update_screenshot_activity_updated_at();