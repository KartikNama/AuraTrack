import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { Mail, Lock, User, Eye, EyeOff, UserPlus } from 'lucide-react'
import { supabase } from '../lib/supabase'
import { useToast } from '../contexts/ToastContext'

interface RegisterProps {
  onLogin?: (userId: string, authUser?: any) => Promise<void> | void
}

export default function Register({ onLogin }: RegisterProps) {
  const [fullName, setFullName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [loading, setLoading] = useState(false)
  const { showError, showSuccess } = useToast()
  const navigate = useNavigate()

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault()

    if (!fullName.trim() || !email.trim() || !password) {
      showError('Please fill in all required fields.')
      return
    }

    if (password.length < 6) {
      showError('Password must be at least 6 characters long.')
      return
    }

    if (password !== confirmPassword) {
      showError('Passwords do not match.')
      return
    }

    try {
      setLoading(true)
      const cleanEmail = email.trim()

      const { data, error } = await supabase.auth.signUp({
        email: cleanEmail,
        password,
        options: {
          data: {
            full_name: fullName.trim(),
          },
        },
      })

      if (error) throw error

      if (data?.user) {
        let session = data.session
        let authUser = data.user

        // If signUp didn't return an active session directly, authenticate immediately with password
        if (!session) {
          const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
            email: cleanEmail,
            password,
          })

          if (!signInError && signInData?.session) {
            session = signInData.session
            authUser = signInData.user
          }
        }

        if (session && onLogin) {
          showSuccess('Account created! Welcome to AuraTrack.')
          await onLogin(authUser.id, authUser)
          navigate('/')
        } else {
          showSuccess('Account created successfully! Signing in...')
          navigate('/login')
        }
      }
    } catch (err: any) {
      showError(err.message || 'Failed to register account.')
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
        <div className="text-center mb-7">
          <div className="inline-flex p-3 rounded-2xl bg-slate-800/80 border border-slate-700/60 shadow-glow-aura mb-4">
            <img 
              src="/auratrack-icon.svg" 
              alt="AuraTrack" 
              className="h-11 w-11"
            />
          </div>
          <div className="flex items-center justify-center space-x-2 mb-1">
            <h1 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-white">
              Create Account
            </h1>
          </div>
          <p className="text-xs sm:text-sm text-slate-400 font-medium">
            Join AuraTrack Enterprise Intelligence
          </p>
        </div>

        <form onSubmit={handleRegister} className="space-y-3.5">
          <div>
            <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-1.5">
              Full Name
            </label>
            <div className="relative">
              <User className="w-4 h-4 text-slate-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                required
                className="w-full pl-10 pr-4 py-2.5 text-sm rounded-xl border border-slate-700/80 bg-slate-800/60 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/50 focus:border-cyan-500/50 transition-all"
                placeholder="Jane Doe"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-1.5">
              Work Email
            </label>
            <div className="relative">
              <Mail className="w-4 h-4 text-slate-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="w-full pl-10 pr-4 py-2.5 text-sm rounded-xl border border-slate-700/80 bg-slate-800/60 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/50 focus:border-cyan-500/50 transition-all"
                placeholder="jane@company.com"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-1.5">
              Password
            </label>
            <div className="relative">
              <Lock className="w-4 h-4 text-slate-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                className="w-full pl-10 pr-11 py-2.5 text-sm rounded-xl border border-slate-700/80 bg-slate-800/60 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/50 focus:border-cyan-500/50 transition-all"
                placeholder="Min. 6 characters"
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

          <div>
            <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-1.5">
              Confirm Password
            </label>
            <div className="relative">
              <Lock className="w-4 h-4 text-slate-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type={showPassword ? 'text' : 'password'}
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                required
                className="w-full pl-10 pr-4 py-2.5 text-sm rounded-xl border border-slate-700/80 bg-slate-800/60 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/50 focus:border-cyan-500/50 transition-all"
                placeholder="••••••••"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full mt-3 flex items-center justify-center space-x-2 py-3 px-4 rounded-xl bg-gradient-to-r from-cyan-500 via-indigo-500 to-purple-600 text-white text-sm font-semibold hover:opacity-95 transition-all shadow-glow-aura disabled:opacity-50 active:scale-[0.99]"
          >
            {loading ? (
              <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
            ) : (
              <>
                <UserPlus className="w-4 h-4" />
                <span>Create Account</span>
              </>
            )}
          </button>
        </form>

        {/* Footer: Sign in link */}
        <div className="mt-6 pt-5 border-t border-slate-800/80 flex flex-col items-center space-y-2 text-xs text-slate-400">
          <div className="flex items-center space-x-1">
            <span>Already have an account?</span>
            <Link
              to="/login"
              className="text-cyan-400 hover:text-cyan-300 font-semibold transition-colors"
            >
              Sign In &rarr;
            </Link>
          </div>
        </div>
      </motion.div>
    </div>
  )
}
