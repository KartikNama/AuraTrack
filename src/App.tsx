import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { useState, useEffect, lazy, Suspense } from 'react'
import { supabase, isSupabaseConfigured } from './lib/supabase'
import { ThemeProvider } from './contexts/ThemeContext'
import { ToastProvider } from './contexts/ToastContext'
import Layout from './components/Layout'
import Loader from './components/Loader'
import type { Tables } from './types/database'

// Lazy load pages for maximum performance
const Dashboard = lazy(() => import('./pages/Dashboard'))
const Attendance = lazy(() => import('./pages/Attendance'))
const Reports = lazy(() => import('./pages/Reports'))
const ProjectManagement = lazy(() => import('./pages/ProjectManagement'))
const TeamMembers = lazy(() => import('./pages/TeamMembers'))
const Screenshots = lazy(() => import('./pages/Screenshots'))
const AdminPanel = lazy(() => import('./pages/AdminPanel'))
const Profile = lazy(() => import('./pages/Profile'))
const Download = lazy(() => import('./pages/Download'))
const Login = lazy(() => import('./pages/Login'))
const Register = lazy(() => import('./pages/Register'))

// Helper function to build redirect URL with query parameters
const buildCallbackRedirectUrl = (callbackUrl: string, params: Record<string, string>) => {
  try {
    if (callbackUrl.includes('://') && !callbackUrl.startsWith('http://') && !callbackUrl.startsWith('https://')) {
      const queryString = new URLSearchParams(params).toString()
      return `${callbackUrl}?${queryString}`
    } else {
      const url = new URL(callbackUrl)
      Object.entries(params).forEach(([key, value]) => {
        url.searchParams.set(key, value)
      })
      return url.toString()
    }
  } catch {
    const queryString = new URLSearchParams(params).toString()
    return `${callbackUrl}?${queryString}`
  }
}

type Profile = Tables<'profiles'>

function App() {
  const [user, setUser] = useState<Profile | null>(null)
  const [loading, setLoading] = useState(true)

  const fetchUserProfile = async (userId: string, authUserParam?: any) => {
    try {
      let authUser = authUserParam
      if (!authUser) {
        const { data: { session } } = await supabase.auth.getSession()
        authUser = session?.user
      }

      const userMetadata = authUser?.user_metadata || {}
      const email = authUser?.email || userMetadata.email || ''
      const fullName = userMetadata.full_name || userMetadata.name || email.split('@')[0] || 'AuraTrack User'

      // Instant fallback profile to ensure UI renders without blocking
      const fallbackProfile: Profile = {
        id: userId,
        email: email,
        full_name: fullName,
        role: 'admin',
        team: null,
        manager_id: null,
        screenshot_interval: 10,
        allow_screenshot_capture: true,
        allow_camera_capture: false,
        force_password_change: false,
        avatar_url: null,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      }

      // Try fetching profile from DB with a strict 2-second timeout so it never hangs
      try {
        const dbPromise = supabase
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle()

        const timeoutPromise = new Promise<any>((resolve) =>
          setTimeout(() => resolve({ data: null, error: new Error('timeout') }), 2000)
        )

        const { data: dbProfile, error: dbError } = await Promise.race([dbPromise, timeoutPromise])

        if (dbProfile) {
          setUser(dbProfile)
          return
        }

        // If profile row doesn't exist yet, attempt background insert
        if (dbError && (dbError.code === 'PGRST116' || !dbProfile)) {
          supabase
            .from('profiles')
            .insert({
              id: userId,
              email: email,
              full_name: fullName,
              role: 'admin',
              team: null,
              manager_id: null,
              force_password_change: false,
            })
            .then(({ data: created }) => {
              if (created) setUser(created as any)
            })
            .catch(() => {})
        }
      } catch (err) {
        console.warn('Profile DB query warning (using local fallback):', err)
      }

      // Set fallback profile immediately
      setUser(fallbackProfile)
    } catch (error) {
      console.error('Error fetching user profile:', error)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    if (!isSupabaseConfigured) {
      setLoading(false)
      return
    }

    let isMounted = true

    // Check if there's a callback URL in the current URL (for desktop app)
    const checkCallbackAndRedirect = async () => {
      try {
        const queryParams = new URLSearchParams(window.location.search)
        const callbackUrl = queryParams.get('callback') || sessionStorage.getItem('oauth_callback_url')
        
        if (callbackUrl) {
          const { data: { session } } = await supabase.auth.getSession()
          if (session?.user) {
            sessionStorage.removeItem('oauth_callback_url')
            const redirectUrl = buildCallbackRedirectUrl(callbackUrl, {
              access_token: session.access_token,
              refresh_token: session.refresh_token || ''
            })
            window.location.href = redirectUrl
            return true
          } else {
            sessionStorage.setItem('oauth_callback_url', callbackUrl)
          }
        }
      } catch (err) {
        console.error('Callback redirect check error:', err)
      }
      return false
    }

    // Check for existing session
    supabase.auth.getSession()
      .then(async ({ data: { session } }) => {
        if (!isMounted) return
        const redirected = await checkCallbackAndRedirect()
        if (redirected) return
        
        if (session?.user) {
          await fetchUserProfile(session.user.id, session.user)
        } else {
          setLoading(false)
        }
      })
      .catch((err) => {
        console.error('Session retrieval error:', err)
        if (isMounted) setLoading(false)
      })

    // Safety timeout so initialization never hangs
    const safetyTimer = setTimeout(() => {
      if (isMounted) setLoading(false)
    }, 2500)

    // Listen for auth state changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (!isMounted) return
      
      const queryParams = new URLSearchParams(window.location.search)
      const callbackUrl = queryParams.get('callback') || sessionStorage.getItem('oauth_callback_url')
      
      if (session?.user && callbackUrl) {
        sessionStorage.removeItem('oauth_callback_url')
        const redirectUrl = buildCallbackRedirectUrl(callbackUrl, {
          access_token: session.access_token,
          refresh_token: session.refresh_token || ''
        })
        window.location.href = redirectUrl
        return
      }
      
      if (session?.user) {
        await fetchUserProfile(session.user.id, session.user)
      } else if (event === 'SIGNED_OUT') {
        setUser(null)
        setLoading(false)
      }
    })

    return () => {
      isMounted = false
      clearTimeout(safetyTimer)
      subscription.unsubscribe()
    }
  }, [])

  // Handle desktop callback when user logs in
  useEffect(() => {
    if (user) {
      const queryParams = new URLSearchParams(window.location.search)
      const callbackUrl = queryParams.get('callback') || sessionStorage.getItem('oauth_callback_url')
      
      if (callbackUrl) {
        supabase.auth.getSession().then(({ data: { session } }) => {
          if (session) {
            sessionStorage.removeItem('oauth_callback_url')
            const redirectUrl = buildCallbackRedirectUrl(callbackUrl, {
              access_token: session.access_token,
              refresh_token: session.refresh_token || ''
            })
            window.location.href = redirectUrl
          }
        }).catch(console.error)
      }
    }
  }, [user])

  if (loading) {
    return (
      <ThemeProvider>
        <ToastProvider>
          <Loader fullScreen size="lg" text="Entering AuraTrack..." />
        </ToastProvider>
      </ThemeProvider>
    )
  }

  return (
    <ThemeProvider>
      <ToastProvider>
        <BrowserRouter>
          <Suspense fallback={<Loader size="lg" />}>
            <Routes>
              {!user ? (
                <>
                  <Route path="/login" element={<Login onLogin={fetchUserProfile} />} />
                  <Route path="/login/direct" element={<Login onLogin={fetchUserProfile} />} />
                  <Route path="/register" element={<Register onLogin={fetchUserProfile} />} />
                  <Route path="*" element={<Navigate to="/login" replace />} />
                </>
              ) : (
                <Route
                  path="*"
                  element={
                    <Layout user={user}>
                      <Routes>
                        <Route path="/" element={<Dashboard user={user} />} />
                        <Route path="/attendance" element={<Attendance user={user} />} />
                        <Route path="/reports" element={<Reports user={user} />} />
                        <Route path="/projects" element={<ProjectManagement user={user} />} />
                        <Route path="/team" element={<TeamMembers user={user} />} />
                        <Route path="/screenshots" element={<Screenshots user={user} />} />
                        <Route 
                          path="/admin" 
                          element={
                            user.role === 'admin' 
                              ? <AdminPanel user={user} /> 
                              : <Navigate to="/" replace />
                          } 
                        />
                        <Route path="/download" element={<Download />} />
                        <Route path="/profile" element={<Profile user={user} onProfileUpdate={fetchUserProfile} />} />
                        <Route path="*" element={<Navigate to="/" replace />} />
                      </Routes>
                    </Layout>
                  }
                />
              )}
            </Routes>
          </Suspense>
        </BrowserRouter>
      </ToastProvider>
    </ThemeProvider>
  )
}

export default App
