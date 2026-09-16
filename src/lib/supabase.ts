import { createClient } from '@supabase/supabase-js'
import type { Database } from '../types/database'

const rawUrl =
  import.meta.env.VITE_SUPABASE_URL ||
  import.meta.env.NEXT_PUBLIC_SUPABASE_URL ||
  ''

const rawAnonKey =
  import.meta.env.VITE_SUPABASE_ANON_KEY ||
  import.meta.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
  ''

export const isSupabaseConfigured = Boolean(
  rawUrl &&
  rawAnonKey &&
  !rawUrl.includes('your-project') &&
  !rawUrl.includes('placeholder')
)

// Safe fallback URL & key to prevent createClient from throwing synchronous runtime crash
const supabaseUrl = rawUrl || 'https://placeholder-auratrack.supabase.co'
const supabaseAnonKey = rawAnonKey || 'placeholder-anon-key'

if (!isSupabaseConfigured) {
  console.warn(
    '[AuraTrack] Supabase credentials not found. Please create a .env file with VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY.'
  )
}

export const supabase = createClient<Database>(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
})
