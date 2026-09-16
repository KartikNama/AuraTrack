import { useState, useEffect } from 'react'
import { Download as DownloadIcon, CheckCircle2, Monitor, Laptop, Sparkles } from 'lucide-react'
import { motion } from 'framer-motion'
import { supabase } from '../lib/supabase'
import { useToast } from '../contexts/ToastContext'
import Loader from '../components/Loader'
import packageJson from '../../package.json'
import { getRequiredTrackerVersion, getAllowedVersionsList } from '../lib/trackerVersion'

// Windows Icon Component
const WindowsIcon = ({ className }: { className?: string }) => (
  <svg
    viewBox="0 0 24 24"
    fill="currentColor"
    className={className}
    xmlns="http://www.w3.org/2000/svg"
  >
    <path d="M3 12V6.75l6-1.5v6.75L3 12zm17-9v8.75l-10 .15V5.21L20 3zM3 13l6 .15v6.75l-6-1.5V13zm17 8v-8.75L10 12.4v6.44l10 1.6z" />
  </svg>
)

// Apple/Mac Icon Component
const AppleIcon = ({ className }: { className?: string }) => (
  <svg
    viewBox="0 0 24 24"
    fill="currentColor"
    className={className}
    xmlns="http://www.w3.org/2000/svg"
  >
    <path d="M17.05 20.28c-.98.95-2.05.88-3.08.4-1.09-.5-2.08-.48-3.24 0-1.44.62-2.2.44-3.06-.4C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09l.01-.01zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z" />
  </svg>
)

export default function Download() {
  const [downloadLinks, setDownloadLinks] = useState({
    windows: '',
    macos: '',
  })
  const [version, setVersion] = useState<string>(packageJson.version)
  const [loading, setLoading] = useState(true)
  const { showError, showInfo } = useToast()

  useEffect(() => {
    fetchDownloadLinks()
    fetchTrackerVersion()
  }, [])

  const fetchTrackerVersion = async () => {
    try {
      const versionSettings = await getRequiredTrackerVersion()
      if (versionSettings && versionSettings.requiredVersion) {
        setVersion(versionSettings.requiredVersion)
        const allowedVersions = getAllowedVersionsList(versionSettings.requiredVersion)
        console.log('[Download App] Allowed desktop versions that can be run:', allowedVersions)
      }
    } catch (error) {
      console.error('Error fetching tracker version:', error)
    }
  }

  const fetchDownloadLinks = async () => {
    try {
      setLoading(true)
      const possibleBuckets = ['tracker-application', 'downloads', 'desktop-apps', 'apps', 'releases']
      
      const windowsFiles = [
        'windows/AuraTrack-Setup.exe',
        'windows/AuraTrack.exe',
        'AuraTrack-Setup.exe',
        'windows/TimeFlow-Setup.exe',
        'windows/TimeFlow.exe',
        'TimeFlow-Setup.exe',
      ]
      const macosFiles = [
        'macos/AuraTrack.dmg',
        'AuraTrack.dmg',
        'macos/TimeFlow.dmg',
        'macos/TimeFlow.app.dmg',
        'TimeFlow.dmg',
      ]

      let foundWindows = ''
      let foundMacos = ''

      for (const bucketName of possibleBuckets) {
        try {
          const { data: listData, error: listError } = await supabase.storage
            .from(bucketName)
            .list('', { limit: 100 })

          if (listError || !listData) continue

          const findFilesRecursively = async (path: string = ''): Promise<string[]> => {
            const { data, error } = await supabase.storage.from(bucketName).list(path, { limit: 100 })
            if (error || !data) return []
            
            const files: string[] = []
            for (const item of data) {
              const fullPath = path ? `${path}/${item.name}` : item.name
              if (item.id === null) {
                const subFiles = await findFilesRecursively(fullPath)
                files.push(...subFiles)
              } else {
                files.push(fullPath)
              }
            }
            return files
          }

          const allFiles = await findFilesRecursively()

          const windowsFile = allFiles.find(file => 
            file.toLowerCase().endsWith('.exe') && 
            (file.toLowerCase().includes('windows') || file.toLowerCase().includes('win') || !file.includes('/'))
          )
          if (windowsFile) {
            const { data } = supabase.storage.from(bucketName).getPublicUrl(windowsFile)
            if (data?.publicUrl) foundWindows = data.publicUrl
          } else {
            for (const filePath of windowsFiles) {
              try {
                const { data } = supabase.storage.from(bucketName).getPublicUrl(filePath)
                if (data?.publicUrl) {
                  foundWindows = data.publicUrl
                  break
                }
              } catch {
                continue
              }
            }
          }

          const macosFile = allFiles.find(file => 
            file.toLowerCase().endsWith('.dmg') && 
            (file.toLowerCase().includes('macos') || file.toLowerCase().includes('mac') || !file.includes('/'))
          )
          if (macosFile) {
            const { data } = supabase.storage.from(bucketName).getPublicUrl(macosFile)
            if (data?.publicUrl) foundMacos = data.publicUrl
          } else {
            for (const filePath of macosFiles) {
              try {
                const { data } = supabase.storage.from(bucketName).getPublicUrl(filePath)
                if (data?.publicUrl) {
                  foundMacos = data.publicUrl
                  break
                }
              } catch {
                continue
              }
            }
          }

          if (foundWindows || foundMacos) {
            setDownloadLinks({
              windows: foundWindows,
              macos: foundMacos,
            })
            setLoading(false)
            return
          }
        } catch (e) {
          continue
        }
      }

      setDownloadLinks({
        windows: '',
        macos: '',
      })
      setLoading(false)
    } catch (error) {
      console.error('Error fetching download links:', error)
      showError('Failed to fetch download links.')
      setLoading(false)
    }
  }

  const handleDownload = async (platform: 'windows' | 'macos', url: string) => {
    if (!url || url === '#') {
      showError(`${platform === 'windows' ? 'Windows' : 'macOS'} build package will be available shortly.`)
      return
    }

    try {
      showInfo(`Initiating download for ${platform === 'windows' ? 'Windows' : 'macOS'} client...`)
      const link = document.createElement('a')
      link.href = url
      link.download = ''
      link.target = '_blank'
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
    } catch (error) {
      console.error('Error downloading file:', error)
      showError('Failed to start download.')
    }
  }

  if (loading) {
    return <Loader size="lg" text="Checking client packages..." />
  }

  return (
    <div className="space-y-8 max-w-6xl mx-auto pb-12">
      {/* Hero Banner */}
      <div className="relative overflow-hidden rounded-3xl p-8 sm:p-12 bg-gradient-to-r from-slate-900 via-indigo-950/70 to-slate-900 border border-slate-800 shadow-2xl">
        <div className="absolute top-0 right-0 w-96 h-96 bg-cyan-500/10 blur-[100px] pointer-events-none rounded-full" />
        <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div className="space-y-3 max-w-xl">
            <div className="inline-flex items-center space-x-2 px-3 py-1 rounded-full bg-cyan-500/10 border border-cyan-500/20 text-cyan-400 text-xs font-semibold">
              <Sparkles className="w-3.5 h-3.5" />
              <span>AuraTrack Client Engine</span>
            </div>
            <h1 className="text-3xl sm:text-4xl font-extrabold text-white tracking-tight">
              Get the AuraTrack Desktop Client
            </h1>
            <p className="text-slate-300 text-sm sm:text-base leading-relaxed">
              Ultra-lightweight background tracker with automated activity sync, smart idle detection, and offline telemetry buffer.
            </p>
          </div>
          <div className="flex flex-col items-start md:items-end">
            <span className="px-4 py-1.5 rounded-xl bg-slate-800/80 border border-slate-700 text-cyan-400 text-sm font-bold shadow-sm">
              Release v{version}
            </span>
            <span className="text-[11px] text-slate-400 mt-1">Automatic silent updates enabled</span>
          </div>
        </div>
      </div>

      {/* Platform Download Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Windows Card */}
        <motion.div
          whileHover={{ y: -4 }}
          className="relative rounded-3xl p-8 bg-white/80 dark:bg-slate-900/80 border border-slate-200 dark:border-slate-800 shadow-lg backdrop-blur-xl flex flex-col justify-between"
        >
          <div>
            <div className="flex items-center justify-between mb-6">
              <div className="w-14 h-14 rounded-2xl bg-cyan-500/10 border border-cyan-500/20 flex items-center justify-center text-cyan-500">
                <WindowsIcon className="w-7 h-7" />
              </div>
              <span className="px-3 py-1 rounded-lg bg-cyan-500/10 text-cyan-600 dark:text-cyan-400 text-xs font-semibold">
                Windows 64-bit
              </span>
            </div>
            <h3 className="text-xl font-bold text-slate-900 dark:text-white mb-2">
              AuraTrack for Windows
            </h3>
            <p className="text-sm text-slate-500 dark:text-slate-400 mb-6">
              Designed for Windows 10 & 11 with minimal RAM overhead and battery-saver mode.
            </p>
          </div>

          <div>
            <button
              onClick={() => handleDownload('windows', downloadLinks.windows)}
              disabled={!downloadLinks.windows}
              className="w-full flex items-center justify-center space-x-2.5 py-3.5 px-6 rounded-2xl bg-gradient-to-r from-cyan-500 to-indigo-600 hover:from-cyan-400 hover:to-indigo-500 text-white font-semibold text-sm shadow-glow-cyan transition-all disabled:opacity-40 disabled:cursor-not-allowed"
            >
              <DownloadIcon className="w-4 h-4" />
              <span>Download Installer (.exe)</span>
            </button>
            <p className="text-[11px] text-center text-slate-400 dark:text-slate-500 mt-3">
              SHA-256 verified binary
            </p>
          </div>
        </motion.div>

        {/* macOS Card */}
        <motion.div
          whileHover={{ y: -4 }}
          className="relative rounded-3xl p-8 bg-white/80 dark:bg-slate-900/80 border border-slate-200 dark:border-slate-800 shadow-lg backdrop-blur-xl flex flex-col justify-between"
        >
          <div>
            <div className="flex items-center justify-between mb-6">
              <div className="w-14 h-14 rounded-2xl bg-purple-500/10 border border-purple-500/20 flex items-center justify-center text-purple-400">
                <AppleIcon className="w-7 h-7" />
              </div>
              <span className="px-3 py-1 rounded-lg bg-purple-500/10 text-purple-600 dark:text-purple-400 text-xs font-semibold">
                Universal Apple Silicon / Intel
              </span>
            </div>
            <h3 className="text-xl font-bold text-slate-900 dark:text-white mb-2">
              AuraTrack for macOS
            </h3>
            <p className="text-sm text-slate-500 dark:text-slate-400 mb-6">
              Optimized for macOS Monterey, Ventura, Sonoma, and Sequoia with native Apple Silicon speed.
            </p>
          </div>

          <div>
            <button
              onClick={() => handleDownload('macos', downloadLinks.macos)}
              disabled={!downloadLinks.macos}
              className="w-full flex items-center justify-center space-x-2.5 py-3.5 px-6 rounded-2xl bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-500 hover:to-indigo-500 text-white font-semibold text-sm shadow-glow-aura transition-all disabled:opacity-40 disabled:cursor-not-allowed"
            >
              <DownloadIcon className="w-4 h-4" />
              <span>Download Disk Image (.dmg)</span>
            </button>
            <p className="text-[11px] text-center text-slate-400 dark:text-slate-500 mt-3">
              Universal binary installer
            </p>
          </div>
        </motion.div>
      </div>

      {/* System Specifications Card */}
      <div className="rounded-3xl p-6 sm:p-8 bg-white/60 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800">
        <h3 className="text-lg font-bold text-slate-900 dark:text-white mb-6 flex items-center space-x-2">
          <Monitor className="w-5 h-5 text-indigo-400" />
          <span>System Compatibility & Verification</span>
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 text-xs text-slate-600 dark:text-slate-300">
          <div className="space-y-2 p-4 rounded-2xl bg-slate-100 dark:bg-slate-800/40 border border-slate-200 dark:border-slate-700/60">
            <div className="font-semibold text-slate-900 dark:text-white flex items-center space-x-1.5">
              <CheckCircle2 className="w-4 h-4 text-emerald-400" />
              <span>Zero-Impact Footprint</span>
            </div>
            <p className="text-slate-500 dark:text-slate-400">Uses less than 35MB RAM in background operation.</p>
          </div>

          <div className="space-y-2 p-4 rounded-2xl bg-slate-100 dark:bg-slate-800/40 border border-slate-200 dark:border-slate-700/60">
            <div className="font-semibold text-slate-900 dark:text-white flex items-center space-x-1.5">
              <CheckCircle2 className="w-4 h-4 text-emerald-400" />
              <span>Offline Telemetry</span>
            </div>
            <p className="text-slate-500 dark:text-slate-400">Buffers attendance locally during network dips and auto-syncs.</p>
          </div>

          <div className="space-y-2 p-4 rounded-2xl bg-slate-100 dark:bg-slate-800/40 border border-slate-200 dark:border-slate-700/60">
            <div className="font-semibold text-slate-900 dark:text-white flex items-center space-x-1.5">
              <CheckCircle2 className="w-4 h-4 text-emerald-400" />
              <span>Hardware Encryption</span>
            </div>
            <p className="text-slate-500 dark:text-slate-400">End-to-end tokenized auth with Microsoft Azure PKCE.</p>
          </div>
        </div>
      </div>
    </div>
  )
}
