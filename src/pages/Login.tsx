import { useState, useEffect } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { Mail, Lock, Eye, EyeOff, LogIn, Sparkles, UserPlus, AlertTriangle } from 'lucide-react'
import { supabase, isSupabaseConfigured } from '../lib/supabase'
import { useToast } from '../contexts/ToastContext'

interface LoginProps {
  onLogin: (userId: string, authUser?: any) => Promise<void> | void
}

export default function Login({ onLogin }: LoginProps) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [loading, setLoading] = useState(false)
  const { showError, showSuccess } = useToast()
  const navigate = useNavigate()

  // Read callback URL from query params (for desktop app integration if applicable)
  const getCallbackUrl = () => {
    const params = new URLSearchParams(window.location.search)
    return params.get('callback')
  }

  const callbackUrl = getCallbackUrl()

  useEffect(() => {
    if (callbackUrl) {
      sessionStorage.setItem('oauth_callback_url', callbackUrl)
    }
  }, [callbackUrl])

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!email || !password) {
      showError('Please enter both email and password.')
      return
    }

    if (!isSupabaseConfigured) {
      showError('Please set your VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY in .env file.')
      return
    }

    try {
      setLoading(true)
      const { data, error } = await supabase.auth.signInWithPassword({
        email: email.trim(),
        password,
      })

      if (error) throw error

      if (data?.user) {
        showSuccess('Welcome back!')
        await onLogin(data.user.id, data.user)

        // If desktop callback was requested, redirect back with tokens
        const storedCallback = callbackUrl || sessionStorage.getItem('oauth_callback_url')
        if (storedCallback && data.session) {
          sessionStorage.removeItem('oauth_callback_url')
          const delimiter = storedCallback.includes('?') ? '&' : '?'
          window.location.href = `${storedCallback}${delimiter}access_token=${data.session.access_token}&refresh_token=${data.session.refresh_token || ''}`
          return
        }

        navigate('/')
      }
    } catch (err: any) {
      showError(err.message || 'Invalid email or password.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-4 relative overflow-hidden bg-slate-950 text-slate-100">
      {/* Dynamic Ambient Background Aura */}
      <div className="absolute top-1/4 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[400px] bg-gradient-to-tr from-cyan-600/20 via-indigo-600/20 to-purple-600/20 blur-[130px] rounded-full pointer-events-none" />
      <div className="absolute -bottom-20 -left-20 w-96 h-96 bg-cyan-600/10 blur-[100px] rounded-full pointer-events-none" />
      <div className="absolute -top-20 -right-20 w-96 h-96 bg-purple-600/10 blur-[100px] rounded-full pointer-events-none" />

      {/* Main Glass Card */}
      <motion.div
        initial={{ opacity: 0, y: 20, scale: 0.98 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ duration: 0.35, ease: 'easeOut' }}
        className="max-w-md w-full relative z-10 backdrop-blur-2xl bg-slate-900/80 border border-slate-800/90 rounded-3xl p-8 sm:p-10 shadow-2xl shadow-indigo-950/50"
      >
        {/* Brand Header */}
        <div className="text-center mb-6">
          <div className="inline-flex p-3 rounded-2xl bg-slate-800/80 border border-slate-700/60 shadow-glow-aura mb-4">
            <img 
              src="/auratrack-icon.svg" 
              alt="AuraTrack" 
              className="h-11 w-11"
            />
          </div>
          <div className="flex items-center justify-center space-x-2 mb-1.5">
            <h1 className="text-3xl font-extrabold tracking-tight text-white">
              Aura<span className="bg-gradient-to-r from-cyan-400 to-indigo-400 bg-clip-text text-transparent">Track</span>
            </h1>
          </div>
          <p className="text-xs sm:text-sm text-slate-400 font-medium">
            Sign in to your productivity dashboard
          </p>
        </div>

        {/* Missing Config Notification */}
        {!isSupabaseConfigured && (
          <div className="mb-6 p-3.5 rounded-2xl bg-amber-500/10 border border-amber-500/30 text-amber-300 text-xs flex items-start space-x-2.5">
            <AlertTriangle className="w-4 h-4 flex-shrink-0 text-amber-400 mt-0.5" />
            <div className="leading-relaxed">
              <strong className="font-semibold block text-amber-200">Database Setup Required</strong>
              Configure <code className="text-amber-300 bg-amber-950/60 px-1 py-0.5 rounded">VITE_SUPABASE_URL</code> in your <code className="text-amber-300 bg-amber-950/60 px-1 py-0.5 rounded">.env</code> file.
            </div>
          </div>
        )}

        {/* Login Form */}
        <form onSubmit={handleLogin} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
              Email Address
            </label>
            <div className="relative">
              <Mail className="w-4 h-4 text-slate-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="w-full pl-10 pr-4 py-3 text-sm rounded-xl border border-slate-700/80 bg-slate-800/60 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/50 focus:border-cyan-500/50 transition-all"
                placeholder="you@company.com"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
              Password
            </label>
            <div className="relative">
              <Lock className="w-4 h-4 text-slate-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                className="w-full pl-10 pr-11 py-3 text-sm rounded-xl border border-slate-700/80 bg-slate-800/60 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/50 focus:border-cyan-500/50 transition-all"
                placeholder="••••••••"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-200 transition-colors"
                tabIndex={-1}
              >
                {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full mt-2 flex items-center justify-center space-x-2 py-3.5 px-4 rounded-xl bg-gradient-to-r from-cyan-500 via-indigo-500 to-purple-600 text-white text-sm font-semibold hover:opacity-95 transition-all shadow-glow-aura disabled:opacity-50 active:scale-[0.99]"
          >
            {loading ? (
              <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
            ) : (
              <>
                <LogIn className="w-4 h-4" />
                <span>Sign In</span>
              </>
            )}
          </button>
        </form>

        {/* Footer: Register link */}
        <div className="mt-8 pt-6 border-t border-slate-800/80 flex flex-col items-center space-y-3 text-xs text-slate-400">
          <div className="flex items-center space-x-1">
            <span>Don't have an account?</span>
            <Link
              to="/register"
              className="text-cyan-400 hover:text-cyan-300 font-semibold transition-colors flex items-center space-x-1"
            >
              <span>Create Account</span>
              <UserPlus className="w-3.5 h-3.5" />
            </Link>
          </div>
          <div className="flex items-center space-x-1 text-slate-500 text-[11px]">
            <Sparkles className="w-3 h-3 text-cyan-400" />
            <span>AuraTrack Secure Identity Provider</span>
          </div>
        </div>
      </motion.div>
    </div>
  )
}
