import { createRequire } from 'module';

const require = createRequire(import.meta.url);

/** @type {import('tailwindcss').Config} */
export default {
  darkMode: 'class',
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['"Plus Jakarta Sans"', 'system-ui', '-apple-system', 'sans-serif'],
      },
      colors: {
        aura: {
          50: '#f0fdf4',
          100: '#e0f2fe',
          200: '#bae6fd',
          300: '#7dd3fc',
          400: '#38bdf8',
          500: '#06b6d4',
          600: '#0284c7',
          700: '#0369a1',
          800: '#075985',
          900: '#0c4a6e',
        },
        indigo: {
          500: '#6366f1',
          600: '#4f46e5',
          700: '#4338ca',
        },
        slate: {
          850: '#111827',
          900: '#0f172a',
          950: '#080c14',
        },
      },
      backgroundImage: {
        'aura-gradient': 'linear-gradient(135deg, #06B6D4 0%, #6366F1 50%, #8B5CF6 100%)',
        'aura-gradient-hover': 'linear-gradient(135deg, #0891B2 0%, #4F46E5 50%, #7C3AED 100%)',
        'dark-mesh': 'radial-gradient(at 0% 0%, rgba(99, 102, 241, 0.15) 0px, transparent 50%), radial-gradient(at 100% 0%, rgba(6, 182, 212, 0.15) 0px, transparent 50%), radial-gradient(at 50% 100%, rgba(139, 92, 246, 0.1) 0px, transparent 50%)',
        'light-mesh': 'radial-gradient(at 0% 0%, rgba(99, 102, 241, 0.08) 0px, transparent 50%), radial-gradient(at 100% 0%, rgba(6, 182, 212, 0.08) 0px, transparent 50%)',
      },
      boxShadow: {
        'glow-aura': '0 0 25px -5px rgba(99, 102, 241, 0.35)',
        'glow-cyan': '0 0 25px -5px rgba(6, 182, 212, 0.35)',
        'glass-card': '0 8px 32px 0 rgba(0, 0, 0, 0.37)',
      },
      backdropBlur: {
        'xs': '2px',
      }
    },
  },
  plugins: [],
};