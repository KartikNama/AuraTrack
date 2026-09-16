import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { motion } from 'framer-motion'
import { Lock, Mail, ArrowLeft, LogIn } from 'lucide-react'
import { supabase } from '../lib/supabase'
import { useToast } from '../contexts/ToastContext'

interface LoginDirectProps {
  onLogin: (userId: string) => void
}

export default function LoginDirect({ onLogin }: LoginDirectProps) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const { showError } = useToast()
  const navigate = useNavigate()

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)

    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      })

      if (error) throw error

      if (data.user) {
        onLogin(data.user.id)
        navigate('/')
      }
    } catch (err: any) {
      showError(err.message || 'Failed to login')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-4 relative overflow-hidden bg-slate-950 text-slate-100">
      {/* Background glow */}
      <div className="absolute top-1/3 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[500px] h-[350px] bg-gradient-to-tr from-cyan-600/15 via-indigo-600/15 to-purple-600/15 blur-[120px] rounded-full pointer-events-none" />

      <motion.div
        initial={{ opacity: 0, y: 15 }}
        animate={{ opacity: 1, y: 0 }}
        className="max-w-md w-full relative z-10 backdrop-blur-2xl bg-slate-900/85 border border-slate-800 rounded-3xl p-8 shadow-2xl shadow-indigo-950/50"
      >
        <Link
          to="/login"
          className="inline-flex items-center space-x-1.5 text-xs text-slate-400 hover:text-cyan-400 mb-6 transition-colors font-medium"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Back to SSO Login</span>
        </Link>

        <div className="text-center mb-8">
          <div className="inline-flex p-3 rounded-2xl bg-slate-800/80 border border-slate-700/60 shadow-glow-aura mb-4">
            <img 
              src="/auratrack-icon.svg" 
              alt="AuraTrack" 
              className="h-10 w-10"
            />
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-white mb-1">
            Direct Authentication
          </h1>
          <p className="text-xs text-slate-400">
            Sign in with administrative credentials
          </p>
        </div>

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
                className="w-full pl-10 pr-4 py-3 text-sm rounded-xl border border-slate-700/80 bg-slate-800/50 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/50 focus:border-cyan-500/50 transition-all"
                placeholder="name@company.com"
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
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                className="w-full pl-10 pr-4 py-3 text-sm rounded-xl border border-slate-700/80 bg-slate-800/50 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-cyan-500/50 focus:border-cyan-500/50 transition-all"
                placeholder="••••••••"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full mt-2 flex items-center justify-center space-x-2 py-3.5 px-4 rounded-xl bg-gradient-to-r from-cyan-500 via-indigo-500 to-purple-600 text-white text-sm font-semibold hover:opacity-95 transition-all shadow-glow-aura disabled:opacity-50"
          >
            {loading ? (
              <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
            ) : (
              <>
                <LogIn className="w-4 h-4" />
                <span>Sign In Directly</span>
              </>
            )}
          </button>
        </form>
      </motion.div>
    </div>
  )
}
