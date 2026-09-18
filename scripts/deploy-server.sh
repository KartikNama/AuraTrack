#!/bin/bash
# ==========================================================
# AuraTrack - Production Server Deployment Script
# ==========================================================
set -e

APP_DIR="/var/www/AuraTrack"
echo "==> Deploying AuraTrack to $APP_DIR..."

cd "$APP_DIR"

# 1. Pull latest code (if using git)
if [ -d ".git" ]; then
  echo "==> Pulling latest changes from git..."
  git pull origin main || true
fi

# 2. Install dependencies
echo "==> Installing dependencies..."
npm install --production=false

# 3. Fix permissions before build so Vite can clean dist
sudo chown -R $USER:$USER "$APP_DIR" 2>/dev/null || true

# 4. Build production bundle (with anti-inspect protection & no sourcemaps)
echo "==> Building production bundle..."
npm run build

# 5. Set directory permissions for Nginx while keeping user ownership
echo "==> Updating permissions for Nginx..."
sudo chown -R $USER:www-data "$APP_DIR/dist" 2>/dev/null || true
sudo chmod -R 755 "$APP_DIR/dist" 2>/dev/null || true

# 6. Reload Nginx
echo "==> Reloading Nginx..."
sudo nginx -t && sudo systemctl reload nginx

echo "✅ AuraTrack successfully deployed and live!"
