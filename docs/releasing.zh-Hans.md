# 打包公证与 Web 部署工作流

FinderActions 支持通过官方开发者签名与公证的拖拽安装 DMG 镜像与 ZIP 压缩包分发；宣传网站基于 Cloudflare Workers + Static Assets 边缘网络托管。

---

## 1. 首次配置与环境要求

### macOS App 打包与公证环境
- 有效的 **Apple Developer Program** 开发者账号。
- `Developer ID Application` 签名证书及私钥已导入 macOS 钥匙串。
- Apple ID App 专用密码（用于 Apple 公证服务 Notary Service）。
- 命令行工具安装（`xcodegen` 用于工程生成，`create-dmg` 用于制作拖拽安装镜像）：
  ```bash
  brew install xcodegen create-dmg
  ```
- 运行引导脚本配置团队 ID 与公证钥匙串档案：
  ```bash
  ./Scripts/setup-signing.sh
  ```
  *(脚本会自动在 `.release.env` 中保存 `DEVELOPMENT_TEAM` 与 `NOTARY_PROFILE=FinderActions-notary`)*。

### 宣传网站部署环境
- **Node.js** (v20+) 与 **npm**。
- 在本地终端完成 Cloudflare 授权登录：
  ```bash
  cd web
  npx wrangler login
  ```
  *(授权成功后本地将获得部署至 Workers 及自定义域名的权限)*。

---

## 2. 版本号管理

在正式发版前，请保持以下三个组件的版本号一致：
- `Apps/Host/Resources/Info.plist`
- `Apps/Settings/Resources/Info.plist`
- `Extensions/FinderSync/Info.plist`

需同步更新的字段：
- `CFBundleShortVersionString`：面向公众的语义化版本号（如 `1.0.0`）。
- `CFBundleVersion`：单调自增的内部构建号（如 `1`）。

---

## 3. macOS App 打包、公证与 DMG 生成

### 一键全自动发版（推荐：`./Scripts/release.sh`）
一条命令自动执行测试、编译、导出、签名校验、公证、票据装订并同时生成 ZIP 与拖拽 DMG 安装包：
```bash
./Scripts/release.sh
```

**底层执行的 8 个流水线步骤：**
1. **自动化测试**：运行 Swift 单元测试（`./Scripts/test.sh`）。
2. **生成 Xcode 工程**：基于 `project.yml` 自动生成干净的 `FinderActions.xcodeproj`。
3. **Release Archive 归档**：使用 Developer ID 证书及安全时间戳编译 Release 归档。
4. **Developer ID 导出**：导出最终的 `FinderActions.app`（包含宿主程序、Settings 辅助程序及 FinderSync 扩展）。
5. **Apple 公证（App）**：压缩并提交至苹果公证服务器（`xcrun notarytool submit`）。
6. **装订公证票据**：执行 `xcrun stapler staple` 装订票据，并通过 `spctl` 验证 Gatekeeper 合规性。
7. **生成发布 ZIP**：打包生成 `FinderActions-<version>-<build>.zip` 及 `.sha256` 校验和。
8. **制作并公证 DMG**：调用 `create-dmg` 生成带 `/Applications` 替身的安装界面，对 DMG 进行 Developer ID 二次签名，提交公证并装订票据，生成 `.dmg.sha256`。

所有产物输出至带时间戳的独立目录：
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

### 单独打包 DMG 镜像（`./Scripts/build-dmg.sh`）
如果本地已有编译并公证好的 `FinderActions.app`，仅需制作或重新打包 DMG 镜像：
```bash
# 自动寻找最新编译好的 FinderActions.app 并生成 DMG：
./Scripts/build-dmg.sh

# 或手动指定输入 App 路径与输出 DMG 路径：
./Scripts/build-dmg.sh build/releases/.../export/FinderActions.app dist/FinderActions-1.0.0.dmg
```

---

## 4. 宣传网站部署 (finderactions.jyeu.xyz)

宣传网页位于 `web/` 目录，采用 Vite + React 19 + Tailwind CSS v4 架构，部署在 **Cloudflare Workers with Static Assets** 平台。

### 一键部署脚本
```bash
./Scripts/deploy-web.sh
```

### 或直接使用 npm
```bash
cd web
npm run deploy
```

**部署机制说明：**
1. 构建前端产物：`tsc -b && vite build`，编译生成静态资源（`dist/client/`）与 Worker 脚本（`dist/finderactions/`）。
2. 调用 `wrangler deploy` 上传资源至 Cloudflare 全球 CDN。
3. `wrangler.jsonc` 中已预置路由规则，请求将自动映射至 `finderactions.jyeu.xyz`，并支持 SPA 页面回退路由与双语实时渲染。

---

## 5. GitHub Release 发布清单

1. 提交并推送最新代码：
   ```bash
   git add .
   git commit -m "chore: release v1.0.0"
   git push origin main
   ```
2. 打 Git Tag 并推送：
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
3. 创建 GitHub Release 并上传资产：
   ```bash
   gh release create v1.0.0 \
     build/releases/<version>-<build>-<timestamp>/FinderActions-1.0.0.dmg \
     build/releases/<version>-<build>-<timestamp>/FinderActions-1.0.0.dmg.sha256 \
     build/releases/<version>-<build>-<timestamp>/FinderActions-1.0.0-1.zip \
     build/releases/<version>-<build>-<timestamp>/FinderActions-1.0.0-1.zip.sha256 \
     --title "FinderActions v1.0.0" \
     --notes "FinderActions 初始公开发布版本。"
   ```
4. 部署最新宣传网页以同步下载地址：
   ```bash
   ./Scripts/deploy-web.sh
   ```

---

## 6. 常见问题排查

### `No Developer ID Application certificate was found`
请确认您的 Apple 开发者证书及关联私钥已导入系统的 `login.keychain-db`。可通过终端查询：
```bash
security find-identity -v -p codesigning
```

### `The notarization Keychain profile is unavailable or invalid`
可重新执行 `./Scripts/setup-signing.sh` 刷新 App 专用密码并写入口令链。

### `Wrangler: fetch failed / 网络连接超时`
在境内环境如果遇到 Cloudflare API 连接问题，可为终端配置代理环境变量后重试：
```bash
export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890
./Scripts/deploy-web.sh
```
