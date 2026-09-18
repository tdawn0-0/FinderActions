# Developer ID Release & Web Deployment Workflow

FinderActions is distributed outside the Mac App Store as a notarized drag-and-drop DMG installer and ZIP archive. Its promotional landing page is hosted on Cloudflare Workers with Static Assets.

---

## 1. One-Time Prerequisites

### For macOS App Release (DMG & ZIP)
- Active **Apple Developer Program** membership.
- `Developer ID Application` certificate and private key installed in macOS Keychain.
- Apple ID App-Specific Password for Apple's Notary Service.
- Command-line tools: `xcodegen` and `create-dmg`:
  ```bash
  brew install xcodegen create-dmg
  ```
- Run the setup wizard once to configure your Team ID and Keychain Notary Profile:
  ```bash
  ./Scripts/setup-signing.sh
  ```
  This creates the ignored `.release.env` file with `DEVELOPMENT_TEAM` and `NOTARY_PROFILE=FinderActions-notary`.

### For Promotional Web Deployment
- **Node.js** (v20+) and **npm**.
- Log in to Cloudflare with Wrangler once in your terminal:
  ```bash
  cd web
  npx wrangler login
  ```
  *(Authorizes Cloudflare Workers and Custom Domain deployments for your account)*.

---

## 2. Versioning

Before creating a new release, ensure version numbers match across all targets:
- `Apps/Host/Resources/Info.plist`
- `Apps/Settings/Resources/Info.plist`
- `Extensions/FinderSync/Info.plist`

Keys to update:
- `CFBundleShortVersionString`: Public semantic version (e.g. `1.0.0`).
- `CFBundleVersion`: Monotonically increasing build number (e.g. `1`).

---

## 3. macOS App Packaging & Release

### One-Click Full Release (`./Scripts/release.sh`)
To run tests, build, export, sign, notarize, staple, and generate both the ZIP and DMG:
```bash
./Scripts/release.sh
```

The script executes 8 automated stages:
1. **Tests**: Runs Swift package unit tests (`./Scripts/test.sh`).
2. **Xcode Project**: Regenerates `FinderActions.xcodeproj` cleanly via `xcodegen`.
3. **Archive**: Compiles Release archive with Developer ID signing and secure timestamps.
4. **Export**: Exports `FinderActions.app` with Developer ID distribution options.
5. **App Notarization**: Submits app archive to Apple's Notary Service (`xcrun notarytool submit`).
6. **Stapling**: Staples ticket (`xcrun stapler staple`) and validates Gatekeeper assessment (`spctl`).
7. **ZIP Distribution**: Creates `FinderActions-<version>-<build>.zip` and `.sha256`.
8. **DMG Installer**: Uses `create-dmg` to produce `FinderActions-<version>.dmg`, signs the DMG with Developer ID, submits DMG to Apple Notary Service, staples the ticket, and calculates `.sha256`.

All artifacts are placed in an immutable timestamped directory:
```text
build/releases/<version>-<build>-<timestamp>/
├── FinderActions.xcarchive
├── export/FinderActions.app
├── FinderActions-<version>-<build>.zip
├── FinderActions-<version>-<build>.zip.sha256
├── FinderActions-<version>.dmg
├── FinderActions-<version>.dmg.sha256
├── FinderActions.entitlements.plist
├── FinderActionsSettings.entitlements.plist
├── FAFinderSync.entitlements.plist
├── notarization.json
└── notarization-dmg.json
```

### Standalone DMG Packaging (`./Scripts/build-dmg.sh`)
If you already have a built `FinderActions.app` and only want to create or recreate the DMG installer:
```bash
# Auto-detects latest built app and creates DMG in the same directory:
./Scripts/build-dmg.sh

# Or specify custom paths:
./Scripts/build-dmg.sh build/releases/.../export/FinderActions.app dist/FinderActions-1.0.0.dmg
```

---

## 4. Promotional Web Deployment

The landing page in `web/` is powered by Vite, React 19, Tailwind CSS v4, and deployed directly to **Cloudflare Workers with Static Assets** bound to custom domain `finderactions.jyeu.xyz`.

### One-Click Script
```bash
./Scripts/deploy-web.sh
```

### Or Direct npm Command
```bash
cd web
npm run deploy
```

What this does:
1. Compiles production assets: `tsc -b && vite build`.
2. Static assets are placed in `dist/client/` and Worker entry in `dist/finderactions/`.
3. `wrangler deploy` syncs the assets to Cloudflare Workers edge network with Single Page Application routing (`not_found_handling: "single-page-application"`).
4. Routes traffic through `finderactions.jyeu.xyz` with automatic TLS/SSL and global CDN caching.

---

## 5. GitHub Release Checklist

1. Commit and push any release changes:
   ```bash
   git add .
   git commit -m "chore: release v1.0.0"
   git push origin main
   ```
2. Create and push Git tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
3. Create GitHub Release:
   ```bash
   gh release create v1.0.0 \
     build/releases/<version>-<build>-<timestamp>/FinderActions-1.0.0.dmg \
     build/releases/<version>-<build>-<timestamp>/FinderActions-1.0.0.dmg.sha256 \
     build/releases/<version>-<build>-<timestamp>/FinderActions-1.0.0-1.zip \
     build/releases/<version>-<build>-<timestamp>/FinderActions-1.0.0-1.zip.sha256 \
     --title "FinderActions v1.0.0" \
     --notes "Initial public release of FinderActions."
   ```
4. Deploy the latest website:
   ```bash
   ./Scripts/deploy-web.sh
   ```

---

## 6. Troubleshooting

### `No Developer ID Application certificate was found`
Ensure your Apple Developer ID certificate and private key are installed in `login.keychain-db`. Verify with:
```bash
security find-identity -v -p codesigning
```

### `The notarization Keychain profile is unavailable or invalid`
Re-run `./Scripts/setup-signing.sh` to generate a fresh app-specific password and store it in the Keychain.

### `Wrangler: fetch failed / connectivity issue`
If using a proxy or VPN in China, ensure terminal proxy environment variables (`http_proxy`, `https_proxy`) are set:
```bash
export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890
cd web && npm run deploy
```
