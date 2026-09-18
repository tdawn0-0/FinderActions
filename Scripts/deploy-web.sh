#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WEB_DIR="$PROJECT_ROOT/web"

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  echo "Error: Node.js and npm are required. Please install them first." >&2
  exit 1
fi

if [[ ! -d "$WEB_DIR" ]]; then
  echo "Error: web directory not found at $WEB_DIR" >&2
  exit 1
fi

echo "=========================================="
echo " Deploying FinderActions Promotional Web  "
echo " Target Domain: finderactions.jyeu.xyz    "
echo "=========================================="

cd "$WEB_DIR"

if [[ ! -d "node_modules" ]]; then
  echo "Installing web dependencies..."
  npm install
fi

echo "[1/2] Building web project for production..."
npm run build

echo "[2/2] Deploying to Cloudflare Workers..."
npx wrangler deploy

echo
echo "=========================================="
echo "✓ Web Deployment Complete!"
echo "Live URL: https://finderactions.jyeu.xyz"
echo "=========================================="

# Optional verification
if command -v curl >/dev/null 2>&1; then
  echo "Verifying live response..."
  HTTP_CODE="$(curl -s -o /dev/null -w "%{http_code}" https://finderactions.jyeu.xyz || echo "000")"
  echo "HTTP Status: $HTTP_CODE"
fi
