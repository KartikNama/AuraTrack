import { useState } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import {
  LayoutDashboard,
  Calendar,
  BarChart3,
  FolderKanban,
  Users,
  Settings,
  User,
  Search,
  LogOut,
  Menu,
  Download,
  Image,
  Sun,
  Moon,
  Zap,
} from 'lucide-react'
import { useTheme } from '../contexts/ThemeContext'
import NotificationBell from './NotificationBell'
import type { Tables } from '../types/database'

type Profile = Tables<'profiles'>

interface LayoutProps {
  children: React.ReactNode
  user: Profile
}

export default function Layout({ children, user }: LayoutProps) {
  const location = useLocation()
  const navigate = useNavigate()
  const { theme, toggleTheme } = useTheme()
  const [sidebarOpen, setSidebarOpen] = useState(true)

  const handleLogout = async () => {
    const { supabase } = await import('../lib/supabase')
    await supabase.auth.signOut()
    navigate('/login')
  }

  const menuItems = [
    { icon: LayoutDashboard, label: 'Dashboard', path: '/' },
    { icon: Calendar, label: 'Attendance', path: '/attendance' },
    { icon: BarChart3, label: 'Reports', path: '/reports' },
    { icon: FolderKanban, label: 'Projects', path: '/projects' },
    { icon: Users, label: 'Team Members', path: '/team' },
    { icon: Image, label: 'Screenshots', path: '/screenshots' },
    ...(user.role === 'admin'
      ? [{ icon: Settings, label: 'Admin Panel', path: '/admin' }]
      : []),
    { icon: Download, label: 'Download App', path: '/download' },
    { icon: User, label: 'Profile', path: '/profile' },
  ]

  return (
    <div className="flex h-screen bg-slate-950 text-slate-100 selection:bg-indigo-500 selection:text-white">
      {/* Sidebar */}
      <aside
        className={`${
          sidebarOpen ? 'w-64' : 'w-20'
        } bg-white/95 dark:bg-slate-900/90 border-r border-slate-200 dark:border-slate-800/80 transition-all duration-300 flex flex-col backdrop-blur-xl z-20`}
      >
        {/* Logo / Header */}
        <div
          className={`h-16 flex items-center border-b border-slate-200 dark:border-slate-800/80 ${
            sidebarOpen ? 'justify-between px-5' : 'justify-center px-2'
          }`}
        >
          {sidebarOpen ? (
            <>
              <Link to="/" className="flex items-center space-x-3 group">
                <div className="relative">
                  <img
                    src="/auratrack-icon.svg"
                    alt="AuraTrack Logo"
                    className="w-8 h-8 rounded-lg shadow-glow-aura transition-transform duration-300 group-hover:scale-105"
                  />
                  <span className="absolute -bottom-0.5 -right-0.5 flex h-2.5 w-2.5">
                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-cyan-400 opacity-75"></span>
                    <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-cyan-500"></span>
                  </span>
                </div>
                <div className="flex flex-col">
                  <span className="text-lg font-extrabold tracking-tight bg-gradient-to-r from-cyan-400 via-indigo-400 to-purple-400 bg-clip-text text-transparent">
                    AuraTrack
                  </span>
                  <span className="text-[9px] font-bold uppercase tracking-widest text-slate-400 dark:text-slate-500">
                    Enterprise
                  </span>
                </div>
              </Link>
              <button
                onClick={() => setSidebarOpen(!sidebarOpen)}
                className="p-1.5 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white transition-colors"
                aria-label="Collapse sidebar"
              >
                <Menu className="w-5 h-5" />
              </button>
            </>
          ) : (
            <button
              onClick={() => setSidebarOpen(!sidebarOpen)}
              className="p-2 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-400 hover:text-slate-900 dark:hover:text-white transition-colors"
              aria-label="Expand sidebar"
            >
              <img
                src="/auratrack-icon.svg"
                alt="AuraTrack"
                className="w-7 h-7"
              />
            </button>
          )}
        </div>

        {/* Navigation */}
        <nav className="flex-1 overflow-y-auto p-3 space-y-1.5">
          {menuItems.map((item) => {
            const Icon = item.icon
            const isActive = location.pathname === item.path
            return (
              <Link
                key={item.path}
                to={item.path}
                title={!sidebarOpen ? item.label : undefined}
                className={`flex items-center space-x-3 px-3.5 py-2.5 rounded-xl text-sm font-medium transition-all duration-200 group relative ${
                  isActive
                    ? 'bg-gradient-to-r from-cyan-500/15 via-indigo-500/15 to-purple-500/15 text-cyan-600 dark:text-cyan-400 border border-cyan-500/30 shadow-sm'
                    : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800/60'
                }`}
              >
                {isActive && (
                  <motion.div
                    layoutId="activeIndicator"
                    className="absolute left-0 top-2 bottom-2 w-1 bg-gradient-to-b from-cyan-400 to-indigo-500 rounded-r-full"
                  />
                )}
                <Icon
                  className={`w-5 h-5 flex-shrink-0 transition-transform duration-200 group-hover:scale-110 ${
                    isActive
                      ? 'text-cyan-500 dark:text-cyan-400'
                      : 'text-slate-500 dark:text-slate-400 group-hover:text-slate-700 dark:group-hover:text-slate-200'
                  }`}
                />
                {sidebarOpen && <span className="truncate">{item.label}</span>}
              </Link>
            )
          })}
        </nav>

        {/* Sidebar Footer Info */}
        {sidebarOpen && (
          <div className="p-3 m-3 rounded-xl bg-gradient-to-br from-indigo-500/10 via-purple-500/5 to-cyan-500/10 border border-indigo-500/20 text-xs">
            <div className="flex items-center space-x-2 text-indigo-400 font-semibold mb-1">
              <Zap className="w-3.5 h-3.5 text-cyan-400" />
              <span>Aura Intelligence</span>
            </div>
            <p className="text-[11px] text-slate-500 dark:text-slate-400 leading-tight">
              Real-time sync active with encrypted telemetry.
            </p>
          </div>
        )}
      </aside>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Header */}
        <header className="h-16 bg-white/80 dark:bg-slate-900/80 border-b border-slate-200 dark:border-slate-800/80 flex items-center justify-between px-6 backdrop-blur-xl z-10">
          <div className="flex items-center flex-1 max-w-md">
            <div className="relative w-full">
              <Search className="absolute left-3.5 top-1/2 transform -translate-y-1/2 w-4 h-4 text-slate-400" />
              <input
                type="text"
                placeholder="Quick search metrics, team, projects..."
                className="w-full pl-10 pr-4 py-2 text-xs md:text-sm rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-950/60 text-slate-900 dark:text-slate-100 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-cyan-500/50 focus:border-cyan-500/50 transition-all"
              />
            </div>
          </div>

          <div className="flex items-center space-x-3">
            {/* Notification Bell */}
            <NotificationBell userId={user.id} />

            {/* Theme Toggle */}
            <button
              onClick={toggleTheme}
              className="p-2 rounded-xl text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 border border-transparent hover:border-slate-200 dark:hover:border-slate-700 transition-all"
              title="Toggle Theme"
              aria-label="Toggle Theme"
            >
              <AnimatePresence mode="wait">
                {theme === 'light' ? (
                  <Moon className="w-4.5 h-4.5 text-indigo-600" />
                ) : (
                  <Sun className="w-4.5 h-4.5 text-amber-400" />
                )}
              </AnimatePresence>
            </button>

            {/* User Profile */}
            <div className="flex items-center space-x-3 pl-2 border-l border-slate-200 dark:border-slate-800">
              <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-cyan-500 via-indigo-500 to-purple-600 flex items-center justify-center text-white text-xs font-bold shadow-md ring-2 ring-slate-800">
                {user.full_name ? user.full_name.charAt(0).toUpperCase() : 'U'}
              </div>
              <div className="hidden sm:flex flex-col">
                <span className="text-xs font-semibold text-slate-800 dark:text-slate-200 max-w-[120px] truncate">
                  {user.full_name || 'User'}
                </span>
                <span className="text-[10px] font-medium text-cyan-500 dark:text-cyan-400 capitalize">
                  {user.role}
                </span>
              </div>
            </div>

            {/* Logout */}
            <button
              onClick={handleLogout}
              className="p-2 rounded-xl text-slate-500 hover:text-rose-500 hover:bg-rose-500/10 transition-colors"
              title="Log out"
              aria-label="Log out"
            >
              <LogOut className="w-4.5 h-4.5" />
            </button>
          </div>
        </header>

        {/* Main Body View */}
        <main className="flex-1 overflow-y-auto p-4 sm:p-6 bg-slate-50/50 dark:bg-transparent">
          {children}
        </main>
      </div>
    </div>
  )
}
