import { createClient } from '@supabase/supabase-js'
import type { Database } from '../types/database'

// Support both VITE_ and NEXT_PUBLIC_ prefixes for compatibility
const supabaseUrl =
  import.meta.env.VITE_SUPABASE_URL ||
  import.meta.env.NEXT_PUBLIC_SUPABASE_URL

const supabaseAnonKey =
  import.meta.env.VITE_SUPABASE_ANON_KEY ||
  import.meta.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

export const supabase = createClient<Database>(supabaseUrl, supabaseAnonKey, {
  auth: {
    flowType: 'pkce', // Explicitly enable PKCE flow for OAuth
    detectSessionInUrl: true, // Automatically detect and handle OAuth callbacks
  },
})

// HRMS Supabase client for leave management
const hrmsSupabaseUrl =
  import.meta.env.VITE_HRMS_SUPABASE_URL ||
  import.meta.env.NEXT_PUBLIC_HRMS_SUPABASE_URL

const hrmsSupabaseAnonKey =
  import.meta.env.VITE_HRMS_SUPABASE_ANON_KEY ||
  import.meta.env.NEXT_PUBLIC_HRMS_SUPABASE_ANON_KEY

export const hrmsSupabase = createClient(hrmsSupabaseUrl, hrmsSupabaseAnonKey)

