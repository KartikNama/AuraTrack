-- Create groups table
CREATE TABLE IF NOT EXISTS groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_by UUID REFERENCES profiles(id) ON DELETE CASCADE,
  manager_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create group_members table
CREATE TABLE IF NOT EXISTS group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_groups_created_by ON groups(created_by);
CREATE INDEX IF NOT EXISTS idx_groups_manager_id ON groups(manager_id);
CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON group_members(user_id);

-- Add RLS (Row Level Security) policies if needed
-- Enable RLS on groups table
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;

-- Enable RLS on group_members table
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view groups they created or groups where they are the manager
CREATE POLICY "Users can view their own groups" ON groups
  FOR SELECT
  USING (
    created_by = auth.uid() OR 
    manager_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('admin', 'hr')
    )
  );

-- Policy: Managers, HR, and Admins can create groups
CREATE POLICY "Managers can create groups" ON groups
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('admin', 'manager', 'hr')
    )
  );

-- Policy: Users can update groups they created or manage
CREATE POLICY "Users can update their groups" ON groups
  FOR UPDATE
  USING (
    created_by = auth.uid() OR 
    manager_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('admin', 'hr')
    )
  );

-- Policy: Users can delete groups they created or manage
CREATE POLICY "Users can delete their groups" ON groups
  FOR DELETE
  USING (
    created_by = auth.uid() OR 
    manager_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('admin', 'hr')
    )
  );

-- Policy: Users can view group members for groups they have access to
CREATE POLICY "Users can view group members" ON group_members
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM groups 
      WHERE groups.id = group_members.group_id 
      AND (
        groups.created_by = auth.uid() OR 
        groups.manager_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM profiles 
          WHERE profiles.id = auth.uid() 
          AND profiles.role IN ('admin', 'hr')
        )
      )
    )
  );

-- Policy: Users can insert group members for groups they manage
CREATE POLICY "Users can add group members" ON group_members
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM groups 
      WHERE groups.id = group_members.group_id 
      AND (
        groups.created_by = auth.uid() OR 
        groups.manager_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM profiles 
          WHERE profiles.id = auth.uid() 
          AND profiles.role IN ('admin', 'hr')
        )
      )
    )
  );

-- Policy: Users can delete group members for groups they manage
CREATE POLICY "Users can remove group members" ON group_members
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM groups 
      WHERE groups.id = group_members.group_id 
      AND (
        groups.created_by = auth.uid() OR 
        groups.manager_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM profiles 
          WHERE profiles.id = auth.uid() 
          AND profiles.role IN ('admin', 'hr')
        )
      )
    )
  );