# Hosting AuraTrack on Server (Alongside MangaH & NexusAI)

This guide provides step-by-step instructions to host **AuraTrack** on the same server alongside **MangaH** (Port 3000 / saudult.xyz) and **NexusAI** (Port 1020).

---

## 1. Server Architecture Overview

| Application | Technology | Internal Port / Root | Domain / Route |
| :--- | :--- | :--- | :--- |
| **MangaH** | Next.js (PM2) | `http://127.0.0.1:3000` | `saudult.xyz` |
| **NexusAI** | Next.js (PM2) | `http://127.0.0.1:1020` | `nexus.yourdomain.com` |
| **AuraTrack** | React SPA (Nginx / Static) | `/var/www/AuraTrack/dist` | `auratrack.yourdomain.com` (or Port 4000) |

---

## 2. Server Setup Commands

### Step A: Clone & Place AuraTrack on Server
SSH into your server:
```bash
# Clone or copy AuraTrack to /var/www/AuraTrack
git clone <your-auratrack-repo-url> /var/www/AuraTrack
cd /var/www/AuraTrack
```

### Step B: Configure Environment Variables
```bash
cp .env.example .env
nano .env
```
Ensure your Supabase keys (`VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`) are properly configured.

### Step C: Build the Application
```bash
npm install
npm run build
```

---

## 3. Nginx Configuration

### Step A: Create Nginx Site Configuration
```bash
sudo cp deploy/nginx/auratrack.conf /etc/nginx/sites-available/auratrack
```
Or edit `/etc/nginx/sites-available/auratrack`:
```nginx
server {
    listen 80;
    server_name auratrack.yourdomain.com;

    root /var/www/AuraTrack/dist;
    index index.html;

    # Gzip Compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml application/json application/javascript application/rss+xml application/atom+xml image/svg+xml;

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # SPA Routing Fallback
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Static Assets Cache
    location ~* \.(?:ico|css|js|gif|jpe?g|png|woff2?|eot|ttf|svg|webp)$ {
        expires 6M;
        access_log off;
        add_header Cache-Control "public, max-age=15552000, immutable";
    }
}
```

### Step B: Enable the Site and Reload Nginx
```bash
# Enable site
sudo ln -sf /etc/nginx/sites-available/auratrack /etc/nginx/sites-enabled/

# Test Nginx configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

### Step C: Enable Free SSL with Let's Encrypt Certbot
```bash
sudo certbot --nginx -d auratrack.yourdomain.com
```

---

## 4. Alternate: Running with PM2 on a Port (e.g. 4000)

If you prefer PM2 process management:
```bash
cd /var/www/AuraTrack
pm2 start ecosystem.config.cjs
pm2 save
```
Then point Nginx to `proxy_pass http://127.0.0.1:4000;`.

---

## 5. Security Features Included in AuraTrack

1. **Context Menu Disabled**: Right-clicking is globally intercepted.
2. **Keyboard Shortcuts Blocked**: `F12`, `Ctrl+Shift+I`, `Ctrl+Shift+J`, `Ctrl+Shift+C`, `Ctrl+Shift+K`, `Ctrl+U`, `Ctrl+S`, `Ctrl+P`, `Shift+F10`, `Cmd+Option+I/J/C` are fully suppressed.
3. **Active DevTools Anti-Debugging Trap**: If DevTools is opened from browser settings or menus, automated debugger traps immediately halt and lock execution.
4. **Console Poisoning & Auto-Clear**: Console functions are neutralized and auto-wiped every second.
5. **No Sourcemaps**: Production build strips source maps so original source code is never exposed.
