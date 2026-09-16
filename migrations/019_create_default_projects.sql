-- Create default projects
DO $$
DECLARE
  default_project_id UUID;
  training_project_id UUID;
  dev_task_id UUID;
  user_record RECORD;
BEGIN
  -- Get Development task ID
  SELECT id INTO dev_task_id FROM tasks WHERE name = 'Development' LIMIT 1;
  
  -- Create "Default Project" for everyone
  INSERT INTO projects (name, description, status, task_id, created_by)
  VALUES (
    'Default Project',
    'Default project for all team members',
    'active',
    dev_task_id,
    (SELECT id FROM profiles WHERE role = 'admin' LIMIT 1)
  )
  ON CONFLICT DO NOTHING
  RETURNING id INTO default_project_id;
  
  -- If project already exists, get its ID
  IF default_project_id IS NULL THEN
    SELECT id INTO default_project_id FROM projects WHERE name = 'Default Project' LIMIT 1;
  END IF;
  
  -- Create "Training" project
  INSERT INTO projects (name, description, status, task_id, created_by)
  VALUES (
    'Training',
    'Training and learning project',
    'active',
    dev_task_id,
    (SELECT id FROM profiles WHERE role = 'admin' LIMIT 1)
  )
  ON CONFLICT DO NOTHING
  RETURNING id INTO training_project_id;
  
  -- If project already exists, get its ID
  IF training_project_id IS NULL THEN
    SELECT id INTO training_project_id FROM projects WHERE name = 'Training' LIMIT 1;
  END IF;
  
  -- Assign all users to Default Project
  FOR user_record IN SELECT id FROM profiles LOOP
    INSERT INTO project_members (project_id, user_id, role)
    VALUES (default_project_id, user_record.id, 'member')
    ON CONFLICT DO NOTHING;
  END LOOP;
  
  -- Assign all users to Training Project
  FOR user_record IN SELECT id FROM profiles LOOP
    INSERT INTO project_members (project_id, user_id, role)
    VALUES (training_project_id, user_record.id, 'member')
    ON CONFLICT DO NOTHING;
  END LOOP;
END $$;