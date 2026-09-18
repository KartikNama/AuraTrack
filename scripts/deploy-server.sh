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

# 3. Build production bundle (with anti-inspect protection & no sourcemaps)
echo "==> Building production bundle..."
npm run build

# 4. Set directory permissions for Nginx
echo "==> Updating permissions..."
sudo chown -R www-data:www-data "$APP_DIR/dist" || true
sudo chmod -R 755 "$APP_DIR/dist" || true

# 5. Reload Nginx
echo "==> Reloading Nginx..."
sudo nginx -t && sudo systemctl reload nginx

echo "✅ AuraTrack successfully deployed and live!"
