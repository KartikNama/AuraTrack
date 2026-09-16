-- Add avatar_url, phone, and location columns to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS avatar_url TEXT,
ADD COLUMN IF NOT EXISTS phone TEXT,
ADD COLUMN IF NOT EXISTS location TEXT;

-- Add comment for documentation
COMMENT ON COLUMN public.profiles.avatar_url IS 'URL to the user profile picture stored in Supabase Storage';
COMMENT ON COLUMN public.profiles.phone IS 'User phone number';
COMMENT ON COLUMN public.profiles.location IS 'User location/address';