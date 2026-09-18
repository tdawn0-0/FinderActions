export const translations = {
  en: {
    nav: {
      features: "Features",
      demo: "Demo",
      scripting: "Scripting",
      architecture: "Architecture",
      guide: "Guide",
      faq: "FAQ",
      github: "GitHub",
      download: "Get Started",
    },
    hero: {
      badge: "Engineered for macOS 15+ Sequoia • Pure Swift 6 & SwiftUI",
      titleStart: "Your Finder. ",
      titleHighlight: "Supercharged Context Actions.",
      subtitle: "The missing right-click power tool for macOS Finder. Copy absolute paths in one click, open folders directly in any terminal or code editor, and run custom shell scripts with a featherweight background (<10MB RAM).",
      ctaPrimary: "View on GitHub",
      ctaSecondary: "Quick Start Guide",
      metaNotice: "Requires macOS 15.0 or later • Free & Open Source (MIT)",
      pillars: [
        {
          id: "paths",
          title: "Copy Absolute Path",
          desc: "Clean file & folder paths without Option key tricks",
        },
        {
          id: "terminals",
          title: "Open in Any Terminal",
          desc: "Ghostty, iTerm2, Warp, Alacritty, Kitty, Terminal",
        },
        {
          id: "editors",
          title: "Open with Any Editor",
          desc: "VS Code, Cursor, Zed, Sublime Text, Xcode",
        },
        {
          id: "scripts",
          title: "Custom Script Plugins",
          desc: "Zsh, Bash, Python, AppleScript with safe argv",
        },
      ],
    },
    demo: {
      tag: "Interactive Simulator",
      title: "Experience it right inside your browser",
      description: "Click on any file or folder below to simulate right-clicking in macOS Finder. Notice how context actions adapt dynamically.",
      mockTitle: "Finder — Project-Assets",
      hintClick: "💡 Right-click (or left-click) any item to summon the Finder context menu",
      actionsExecuted: "Executed Action",
      toastTitle: "FinderActions Notification",
      sidebar: {
        favorites: "Favorites",
        airdrop: "AirDrop",
        recents: "Recents",
        applications: "Applications",
        desktop: "Desktop",
        documents: "Documents",
        downloads: "Downloads",
        icloud: "iCloud Drive",
        tags: "Tags",
        work: "Work",
        personal: "Personal",
      },
      files: [
        { name: "hero-banner.png", size: "1.4 MB", type: "Image", matched: ["convert-webp", "copy-path", "compress"] },
        { name: "api-schema.json", size: "18 KB", type: "JSON", matched: ["format-json", "open-vscode", "copy-path"] },
        { name: "deploy-pipeline.sh", size: "3.2 KB", type: "Shell Script", matched: ["open-terminal", "open-vscode", "copy-path"] },
        { name: "design-spec.pdf", size: "4.8 MB", type: "Document", matched: ["copy-path", "compress"] },
        { name: "build-artifacts", size: "12 items", type: "Folder", matched: ["open-terminal", "open-vscode", "copy-path", "compress"] },
      ],
      contextMenuHeader: "Quick Actions",
      menuItems: {
        openTerminal: "Open in Ghostty / Terminal",
        openEditor: "Open in VS Code / Cursor",
        copyPath: "Copy Absolute Path",
        copyName: "Copy Filename",
        compress: "Compress to Archive (.zsh)",
        convertWebp: "Convert to WebP Image (.zsh)",
        formatJson: "Format JSON with jq (.zsh)",
      },
      toastFeedback: {
        openTerminal: "Opened Ghostty terminal at: ~/Project-Assets",
        openEditor: "Launched VS Code with target file",
        copyPath: "Copied absolute path to clipboard!",
        copyName: "Copied filename to clipboard!",
        compress: "Archive created successfully (exit 0)",
        convertWebp: "Optimized image converted to WebP format",
        formatJson: "JSON formatted and validated with jq",
      }
    },
    scripting: {
      tag: "Scripts As Plugins",
      title: "No proprietary SDK. Just plain shell scripts.",
      description: "Every action is an executable script and a manifest entry in JSON. Safe argv arrays, whitespace safe, and easily shared with your team.",
      tabScript: "compress.zsh",
      tabManifest: "manifest.json",
      tabOutput: "Activity Logs (exec.jsonl)",
      copyCode: "Copy Code",
      copied: "Copied!",
      pathCallout: "Stored in ~/Library/Application Support/FinderActions/",
    },
    features: {
      tag: "Core Capabilities",
      title: "Essential productivity actions, built natively",
      subtitle: "Designed around the actual day-to-day needs of Mac power users and developers, without the bloat.",
      bento: [
        {
          id: "paths",
          badge: "Essential Utility",
          title: "Copy Absolute Paths in One Click",
          desc: "Never struggle with Option+Right Click again. Right-click any file or directory in Finder to copy its clean, unescaped absolute path directly to your clipboard. Supports multi-selection batch copying seamlessly.",
        },
        {
          id: "terminals",
          badge: "Terminal Hub",
          title: "Open Folders in Any Terminal",
          desc: "Instant launch into your preferred terminal: Ghostty, iTerm2, Warp, Alacritty, Kitty, or native macOS Terminal. Right-click any directory to spawn a shell directly at the target location.",
        },
        {
          id: "editors",
          badge: "Editor Hub",
          title: "Open with Any Code Editor",
          desc: "Right-click to open files, folders, or entire projects with VS Code, Cursor, Zed, Sublime Text, Xcode, JetBrains, or any custom macOS .app configured in your settings.",
        },
        {
          id: "scripts",
          badge: "Scripts as Plugins",
          title: "Full Custom Scripting Freedom",
          desc: "Write actions in Zsh, Bash, Python, or AppleScript. Scripts are plain files stored locally and receive file paths safely via native argv arrays (\"$@\") without shell-injection risk.",
        },
        {
          id: "lightweight",
          badge: "< 10 MB RAM",
          title: "Pure Swift Native, Zero Idle CPU",
          desc: "No bloated Electron runtime. A featherweight resident host that consumes <10MB memory with a very thin background, paired with an on-demand SwiftUI settings helper.",
        },
        {
          id: "privacy",
          badge: "100% Local",
          title: "Zero Telemetry, Local-First",
          desc: "No telemetry, no tracking, no accounts, no subscriptions. Everything runs locally on your Mac, completely open-source under the MIT license.",
        },
      ]
    },
    architecture: {
      tag: "Under The Hood",
      title: "Three-tier architecture without the legacy drag",
      subtitle: "Traditional Mac App Store sandbox apps require complex security-scoped bookmark relays and heavyweight helpers. FinderActions takes a cleaner, modern path with a featherweight background.",
      hostTitle: "Host (Resident Core)",
      hostDesc: "Non-sandboxed, lightweight menu bar controller and execution engine. Spawns processes, manages logs, and publishes menu snapshots via DistributedNotification.",
      settingsTitle: "Settings Helper (SwiftUI)",
      settingsDesc: "Modern SwiftUI 6 interface (@Observable). Starts only when requested, saves configuration, and terminates immediately upon window closure.",
      syncTitle: "FinderSync (Sandboxed UI Probe)",
      syncDesc: "Extremely thin extension. Reads the cached menu snapshot, renders the menu in Finder, and forwards click events in microseconds.",
      comparisonTitle: "FinderActions vs Traditional Apps",
      compRows: [
        { label: "Idle Memory", fa: "< 10 MB", others: "150 MB - 400 MB (Electron/Node)" },
        { label: "Idle CPU", fa: "0.0%", others: "0.5% - 2.0% constant polling" },
        { label: "Settings Process", fa: "Exits on window close", others: "Runs forever in background" },
        { label: "Script Storage", fa: "Plain .zsh / .sh / .py files", others: "Proprietary database or cloud" },
        { label: "Network Activity", fa: "Zero (No outgoing calls)", others: "Telemetry & licensing checks" },
        { label: "License & Cost", fa: "Open Source (MIT) • Free", others: "Monthly subscription ($5-10/mo)" }
      ]
    },
    guide: {
      tag: "Get Started in 60s",
      title: "Up and running in three simple steps",
      step1Title: "1. Download & Move to /Applications",
      step1Desc: "Grab the latest notarized release from GitHub Releases (ZIP / DMG).",
      step2Title: "2. Enable Finder Extension",
      step2Desc: "Open System Settings → Privacy & Security → Extensions, and toggle FinderActions on.",
      step3Title: "3. Right-Click in Finder",
      step3Desc: "Open any folder in Finder, right-click on files, and start triggering your actions!",
      troubleTitle: "Troubleshooting Menu on Sequoia+",
      troubleDesc: "If macOS Sequoia doesn't immediately activate the FinderSync extension, run this one-liner in Terminal to register and restart Finder:",
    },
    faq: {
      tag: "Frequently Asked Questions",
      title: "Everything you need to know",
      items: [
        {
          q: "Does FinderActions work on older macOS versions like Sonoma or Ventura?",
          a: "FinderActions is specifically engineered for macOS 15 Sequoia and later, leveraging the newest Swift 6 concurrency models, updated FinderSync capabilities, and modern SwiftUI optimizations. We intentionally do not carry legacy compatibility baggage."
        },
        {
          q: "Why is the Host process not sandboxed?",
          a: "A sandboxed host cannot execute arbitrary command-line tools (like git, ffmpeg, zsh scripts, or custom developer utilities) without tedious security-scoped bookmark relays that often corrupt or prompt incessantly. By signing with Developer ID and Hardened Runtime, FinderActions executes directly and safely."
        },
        {
          q: "Can I write actions in Python, Node.js, or AppleScript?",
          a: "Yes! In your manifest.json, set the interpreter to /usr/bin/python3, /usr/local/bin/node, /usr/bin/osascript, or your preferred runtime. As long as the binary exists on your Mac, FinderActions can run it."
        },
        {
          q: "How are paths passed to scripts safely?",
          a: "FinderActions invokes scripts via Process with an argv array. Paths are passed directly as individual arguments, so you iterate over \"$@\" in Zsh. Special characters, spaces, quotes, and non-ASCII paths will never break execution."
        },
        {
          q: "Is Full Disk Access required?",
          a: "Granting Full Disk Access to FinderActions.app in System Settings is recommended so your scripts can interact with protected locations (like Desktop, Documents, or external volumes) without encountering macOS permission dialogs."
        }
      ]
    },
    footer: {
      tagline: "The scriptable right-click launcher for macOS power users.",
      license: "Released under the open-source MIT License.",
      github: "GitHub Repository",
      releases: "Releases & Changelog",
      builtWith: "Crafted with Swift 6 and SwiftUI for macOS.",
      backToTop: "Back to top ↑"
    }
  },
  zh: {
    nav: {
      features: "核心功能",
      demo: "交互演示",
      scripting: "脚本生态",
      architecture: "底层架构",
      guide: "上手指南",
      faq: "常见问题",
      github: "GitHub",
      download: "快速上手",
    },
    hero: {
      badge: "专为 macOS 15+ Sequoia 打造 • 纯原生 Swift 6 与 SwiftUI",
      titleStart: "让访达右键，",
      titleHighlight: "随心调用，得心应手。",
      subtitle: "macOS 访达右键必备效率利器。右键一键复制文件绝对路径，在各类终端中瞬间打开文件夹，使用任意编辑器直接打开工程，并支持编写任意自定义脚本。轻量纯原生、极薄后台（<10MB 内存）、100% 本地隐私。",
      ctaPrimary: "在 GitHub 上查看",
      ctaSecondary: "快速上手指南",
      metaNotice: "兼容 macOS 15.0 及以上 • 自由开源 (MIT 许可)",
      pillars: [
        {
          id: "paths",
          title: "复制文件绝对路径",
          desc: "单选/多选一键复制，彻底告别繁琐按键",
        },
        {
          id: "terminals",
          title: "各类终端直接打开",
          desc: "Ghostty / iTerm2 / Warp / Kitty / Terminal",
        },
        {
          id: "editors",
          title: "各类编辑器一键载入",
          desc: "VS Code / Cursor / Zed / Xcode / Sublime",
        },
        {
          id: "scripts",
          title: "支持自定义动作脚本",
          desc: "Zsh / Bash / Python / AppleScript 参数安全传递",
        },
      ],
    },
    demo: {
      tag: "交互式拟真演示",
      title: "在浏览器中亲身体验右键魔法",
      description: "点击下方模拟 Finder 中的任意文件或文件夹，即可唤起真实拟真的 macOS 右键菜单，感受上下文自适应过滤与即时动作反馈。",
      mockTitle: "访达 — Project-Assets",
      hintClick: "💡 右键（或点击）任意文件，即可唤起访达右键动作菜单",
      actionsExecuted: "已执行动作",
      toastTitle: "FinderActions 系统通知",
      sidebar: {
        favorites: "个人收藏",
        airdrop: "隔空投送",
        recents: "最近使用",
        applications: "应用程序",
        desktop: "桌面",
        documents: "文稿",
        downloads: "下载",
        icloud: "iCloud 云盘",
        tags: "标签",
        work: "工作",
        personal: "个人",
      },
      files: [
        { name: "hero-banner.png", size: "1.4 MB", type: "图像", matched: ["convert-webp", "copy-path", "compress"] },
        { name: "api-schema.json", size: "18 KB", type: "JSON", matched: ["format-json", "open-vscode", "copy-path"] },
        { name: "deploy-pipeline.sh", size: "3.2 KB", type: "Shell 脚本", matched: ["open-terminal", "open-vscode", "copy-path"] },
        { name: "design-spec.pdf", size: "4.8 MB", type: "文稿", matched: ["copy-path", "compress"] },
        { name: "build-artifacts", size: "12 项", type: "文件夹", matched: ["open-terminal", "open-vscode", "copy-path", "compress"] },
      ],
      contextMenuHeader: "快捷动作",
      menuItems: {
        openTerminal: "在 Ghostty / 终端中打开",
        openEditor: "用 VS Code / Cursor 打开",
        copyPath: "复制完整绝对路径",
        copyName: "复制文件名",
        compress: "快速打包压缩 (.zsh)",
        convertWebp: "转为 WebP 格式 (.zsh)",
        formatJson: "使用 jq 格式化 JSON (.zsh)",
      },
      toastFeedback: {
        openTerminal: "已在 Ghostty 中打开目录：~/Project-Assets",
        openEditor: "已在 VS Code 中载入目标文件",
        copyPath: "已成功将文件绝对路径复制至剪贴板！",
        copyName: "已成功将文件名复制至剪贴板！",
        compress: "压缩包创建成功 (exit code: 0)",
        convertWebp: "图片已无损转换为 WebP 格式",
        formatJson: "JSON 文件已格式化并通过语法校验",
      }
    },
    scripting: {
      tag: "脚本即插件",
      title: "无需专有 SDK，写 Shell 就是写扩展",
      description: "每个右键动作都是一个可直接运行的脚本和一个 JSON 清单项。原生 argv 参数数组传递，天然免疫空格、单引号和中文乱码，版本管理得心应手。",
      tabScript: "compress.zsh",
      tabManifest: "manifest.json",
      tabOutput: "运行日志 (exec.jsonl)",
      copyCode: "复制代码",
      copied: "已复制！",
      pathCallout: "配置与脚本统一存储于 ~/Library/Application Support/FinderActions/",
    },
    features: {
      tag: "四大核心功能",
      title: "为 Mac 极客与开发者打造的高频刚需",
      subtitle: "聚焦开发工作流中最常重复的痛点，用最轻量纯粹的系统扩展予以解决。",
      bento: [
        {
          id: "paths",
          badge: "效率刚需",
          title: "访达右键一键复制文件绝对路径",
          desc: "彻底告别繁琐的「按住 Option 再右键」痛点。右键任意文件或目录即可直接将干净、无特殊符号转义烦恼的完整绝对路径复制到剪贴板，支持批量多选一键复制。",
        },
        {
          id: "terminals",
          badge: "终端直达",
          title: "在各类终端中秒开目标文件夹",
          desc: "深度支持 Ghostty、iTerm2、Warp、Alacritty、Kitty 以及系统原生终端。在访达任意文件夹右键即可自动拉起终端并 cd 至当前路径，快如闪电。",
        },
        {
          id: "editors",
          badge: "编辑器联动",
          title: "右键使用各类编辑器瞬间打开",
          desc: "在访达中选中文件或项目文件夹，右键即可直接唤起 VS Code、Cursor、Zed、Sublime Text、Xcode、JetBrains 或系统中安装的任意编辑器应用。",
        },
        {
          id: "scripts",
          badge: "脚本即插件",
          title: "支持编写任意自定义动作脚本",
          desc: "无需学习专有 SDK，直接使用 Zsh、Bash、Python 或 AppleScript 编写业务动作。原生 argv 参数数组传递（\"$@\"），天然免疫空格与特殊字符，可随心用 git 备份与分享。",
        },
        {
          id: "lightweight",
          badge: "< 10 MB 内存",
          title: "原生极简架构，闲置零 CPU",
          desc: "告别笨重臃肿的 Electron 包装器。仅有很薄的原生后台与微小内存占用（<10MB），闲置 CPU 恒定为 0%，SwiftUI 设置窗口关闭即彻底退出释放资源。",
        },
        {
          id: "privacy",
          badge: "100% 隐私",
          title: "零遥测上报，零云端依赖",
          desc: "无任何埋点、绝不发起网络连接、无账号与订阅。所有执行逻辑与日志完全留存于本地，基于 MIT 开源协议百分之百透明放心。",
        },
      ]
    },
    architecture: {
      tag: "技术底座",
      title: "三层精简架构，彻底摆脱历史包袱",
      subtitle: "传统 Mac App Store 沙盒应用依赖繁琐的辅助进程与安全书签（Bookmark）中继链路。FinderActions 采用更纯粹现代的技术路径，保持极薄后台与极低内存占用。",
      hostTitle: "Host（轻量常驻核心）",
      hostDesc: "非沙盒、轻量级菜单栏与执行控制器。负责拉起子进程、管理日志，并通过 DistributedNotification 发布右键菜单快照。",
      settingsTitle: "Settings Helper（SwiftUI 设置助手）",
      settingsDesc: "现代 SwiftUI 6 界面（@Observable）。仅在用户需要调整配置时启动，保存后立即退出，绝不在后台常驻吃内存。",
      syncTitle: "FinderSync（沙盒极薄 UI 探针）",
      syncDesc: "极致轻薄的系统扩展。只读取缓存的菜单快照并在 Finder 中渲染，点击后在微秒级时间内转发事件，不执行任何重脚本。",
      comparisonTitle: "FinderActions 与传统同类工具对比",
      compRows: [
        { label: "常驻闲置内存", fa: "< 10 MB", others: "150 MB - 400 MB (Electron/Node)" },
        { label: "常驻闲置 CPU", fa: "0.0%", others: "0.5% - 2.0% 持续轮询唤醒" },
        { label: "设置窗口生命周期", fa: "关窗即完全退出", others: "始终常驻后台占用资源" },
        { label: "脚本配置格式", fa: "纯文本 .zsh / .sh / .py", others: "专有二进制数据库或云端同步" },
        { label: "网络行为", fa: "完全无网络请求", others: "遥测分析、广告与许可校验" },
        { label: "收费模式", fa: "开源 (MIT) • 完全免费", others: "按月订阅收费 ($5-10/月)" }
      ]
    },
    guide: {
      tag: "60 秒快速上手",
      title: "仅需三步，开启效率飞升",
      step1Title: "1. 下载并拖入 /Applications",
      step1Desc: "从 GitHub Releases 获取经苹果公证的免安装发布版本（ZIP / DMG）。",
      step2Title: "2. 在系统设置中启用访达扩展",
      step2Desc: "打开「系统设置 → 隐私与安全性 → 扩展」，勾选启用 FinderActions 访达扩展插件。",
      step3Title: "3. 在访达中右键即可触发",
      step3Desc: "在访达中选中任意文件或目录，右键即可看见自定义动作菜单！",
      troubleTitle: "Sequoia 菜单未即时显示排查",
      troubleDesc: "若 macOS Sequoia 未立即激活 FinderSync 扩展，在终端执行以下单行命令即可快速注册并重启访达：",
    },
    faq: {
      tag: "常见问题解答",
      title: "关于 FinderActions 的一切",
      items: [
        {
          q: "FinderActions 是否支持旧版 macOS（如 Sonoma 或 Ventura）？",
          a: "FinderActions 专为 macOS 15 Sequoia 及以上版本设计，采用了 Swift 6 最新并发模型与现代化 SwiftUI 界面设计，不背负历史兼容包袱，确保最前沿系统的极速体验。"
        },
        {
          q: "为什么 Host 进程没有开启沙盒？",
          a: "沙盒应用无法直接自由调用终端常用开发工具（如 git、ffmpeg、zsh 脚本等），通常需要复杂且脆弱的 security-scoped 书签中继。FinderActions 通过 Developer ID 签名与 Hardened Runtime，确保安全的同时直接执行，简单稳健。"
        },
        {
          q: "我可以使用 Python、Node.js 或 AppleScript 编写脚本吗？",
          a: "当然可以！在 manifest.json 中将 interpreter 设置为 /usr/bin/python3、/usr/local/bin/node 或 /usr/bin/osascript 等。只要系统存在对应解释器，就能直接无缝执行。"
        },
        {
          q: "脚本是如何安全接收文件路径的？",
          a: "FinderActions 采用 Process 的 argv 参数数组传递路径，绝不执行拼接字符串的 shell 命令。在脚本中直接通过 \"$@\" 循环即可，包含空格、引号、Emoji 和中文字符都能百分之百安全解析。"
        },
        {
          q: "需要授予完全磁盘访问权限（Full Disk Access）吗？",
          a: "建议在「系统设置 → 隐私与安全性 → 完全磁盘访问权限」中将 FinderActions 添加进去，这样你的脚本在操作桌面、文稿或移动硬盘等受保护目录时便不会被系统反复弹窗阻断。"
        }
      ]
    },
    footer: {
      tagline: "专为 Mac 开发者打造的可脚本化访达右键动作中枢。",
      license: "基于 MIT 开源协议开放全部源代码。",
      github: "GitHub 仓库",
      releases: "版本发布与更新日志",
      builtWith: "使用 Swift 6 与 SwiftUI 倾心打造。",
      backToTop: "回到顶部 ↑"
    }
  }
};

export const codeSnippets = {
  script: `#!/bin/zsh
set -euo pipefail

# Injected environment variables:
# "$@"           Selected absolute paths (space/quote/unicode safe!)
# $FA_CWD        Current Finder container directory
# $FA_PATHS      Newline-separated paths
# $FA_PATH_COUNT Number of selected items
# $FA_ACTION_ID  Action ID from manifest

echo "🚀 Packaging $FA_PATH_COUNT item(s)..."

for f in "$@"; do
  out_name="\${f:t:r}.tar.gz"
  echo "Compressing: \${f:t} -> $out_name"
  tar -czf "\${f:h}/$out_name" -C "\${f:h}" "\${f:t}"
done

echo "✅ Compressed $# file(s) into archives!"
exit 0`,

  manifest: `{
  "id": "compress-archive",
  "name": "Compress to Archive",
  "type": "shell",
  "enabled": true,
  "sortIndex": 10,
  "icon": {
    "sfSymbol": "archivebox.fill"
  },
  "showWhen": {
    "target": "filesAndFolders",
    "minSelection": 1
  },
  "shell": {
    "interpreter": "/bin/zsh",
    "scriptFile": "compress.zsh"
  }
}`,

  output: `[2026-09-18T14:10:02+08:00] EXEC START: action=compress-archive
> Working Dir: /Users/developer/Project-Assets
> Arguments (1):
  [0] /Users/developer/Project-Assets/hero-banner.png
> Environment:
  FA_PATH_COUNT=1
  FA_CWD=/Users/developer/Project-Assets
  FA_ACTION_ID=compress-archive

[STDOUT] 🚀 Packaging 1 item(s)...
[STDOUT] Compressing: hero-banner.png -> hero-banner.tar.gz
[STDOUT] ✅ Compressed 1 file(s) into archives!
[EXIT CODE] 0 (SUCCESS)
[NOTIFICATION] Posted macOS banner notification: "✅ Compressed 1 file(s) into archives!"`
};
