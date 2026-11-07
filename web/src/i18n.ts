import compressActionManifest from './examples/compress-action.json?raw';

export const translations = {
  en: {
    nav: {
      demo: "Demo",
      features: "Capabilities",
      scripting: "Scripts",
      architecture: "Architecture",
      guide: "Install",
      faq: "FAQ",
      github: "GitHub",
      download: "Download",
    },
    hero: {
      title: "Finder context-menu actions as plain scripts.",
      ctaDownload: "Download for macOS",
      ctaGithub: "Source on GitHub",
      meta: "macOS 15+ · Universal · MIT",
    },
    demo: {
      sidebar: {
        favorites: "Favorites",
        recents: "Recents",
        applications: "Applications",
        documents: "Documents",
        tags: "Tags",
        work: "Work",
        personal: "Personal",
      },
      menuItems: {
        openTerminal: "Open in Terminal — Ghostty",
        openEditor: "Open in Cursor",
        copyPath: "Copy Path",
        copyName: "Copy Filename",
        compress: "Compress Archive",
        convertWebp: "Convert to WebP",
        formatJson: "Format JSON",
      },
      toastFeedback: {
        openTerminal: "Opened Ghostty at ~/Project-Assets",
        openEditor: "Opened in Cursor",
        copyPath: "/Users/dev/Project-Assets copied",
        copyName: "Filename copied",
        compress: "Created archive (exit 0)",
        convertWebp: "Converted to WebP (exit 0)",
        formatJson: "Formatted JSON (exit 0)",
      },
    },
    features: {
      items: [
        {
          id: "paths",
          title: "Copy Path & Filename",
          desc: "Copies clean absolute paths or basenames for one or multiple selected items.",
        },
        {
          id: "terminals",
          title: "Open in Terminal",
          desc: "Ghostty, iTerm2, Warp, Alacritty, Kitty, macOS Terminal, or any custom app.",
        },
        {
          id: "editors",
          title: "Open with Editor",
          desc: "VS Code, Cursor, Zed, Xcode, Sublime Text, JetBrains, or custom applications.",
        },
        {
          id: "scripts",
          title: "Shell & AppleScript",
          desc: "Receives selected paths as direct argv arrays (\"$@\"). Import and export .faaction packages.",
        },
      ],
    },
    scripting: {
      title: "Scripts & Manifest",
      tabScript: "compress.zsh",
      tabManifest: "manifest.json",
      tabOutput: "exec.jsonl",
      copyCode: "Copy",
      copied: "Copied",
      pathCallout: "~/Library/Application Support/FinderActions/",
    },
    architecture: {
      title: "Architecture",
      hostTitle: "Host",
      hostMeta: "Resident · <10 MB",
      hostDesc: "AppKit menu-bar process. Owns manifest, runs scripts off the main thread, writes logs, and publishes menu snapshots.",
      settingsTitle: "Settings",
      settingsMeta: "On-demand · SwiftUI",
      settingsDesc: "Launches only while editing actions, testing inputs, or inspecting logs. Terminates when closed.",
      syncTitle: "FinderSync",
      syncMeta: "Sandboxed Extension",
      syncDesc: "Renders cached menu snapshots inside Finder and forwards selected paths to Host.",
      compHeaders: ["Metric", "FinderActions", "Electron / Sandbox Helpers"],
      compRows: [
        { label: "Idle Memory", fa: "< 10 MB", others: "150–400 MB" },
        { label: "Idle CPU", fa: "0%", others: "Background polling" },
        { label: "Settings Process", fa: "Exits on close", others: "Resident" },
        { label: "Script Storage", fa: "Plain files + JSON", others: "Opaque database" },
        { label: "Network", fa: "None", others: "Telemetry / license checks" },
        { label: "License", fa: "MIT", others: "Proprietary" },
      ],
    },
    guide: {
      title: "Install",
      step1Title: "1. Move to /Applications",
      step1Desc: "Download the notarized DMG or ZIP from GitHub Releases and drag FinderActions to /Applications.",
      downloadLink: "Latest Release ›",
      step2Title: "2. Enable Finder Extension",
      step2Desc: "Open System Settings → General → Login Items & Extensions → Finder, and turn FinderActions on.",
      step3Title: "3. Verify in Finder",
      step3Desc: "Right-click any file in Finder and run Copy Path to confirm end-to-end setup.",
      troubleTitle: "Reset FinderSync registration (Terminal)",
      copyCmd: "Copy",
      copiedCmd: "Copied",
    },
    faq: {
      title: "FAQ",
      items: [
        {
          q: "Which macOS versions are supported?",
          a: "macOS 15 Sequoia and later (Universal Apple Silicon & Intel).",
        },
        {
          q: "Why is the Host process non-sandboxed?",
          a: "A sandboxed process cannot invoke user CLI tools (git, ffmpeg, jq, homebrew binaries) without per-folder security-scoped bookmarks. Host is signed with Developer ID and Hardened Runtime.",
        },
        {
          q: "Can I use Python, Node, or Ruby?",
          a: "Yes. Set the action's Shell field to /usr/bin/python3, /opt/homebrew/bin/node, or any executable interpreter.",
        },
        {
          q: "How are spaces and Unicode paths handled?",
          a: "Paths are passed as direct Process argv elements rather than shell-interpolated strings. Iterate over \"$@\" safely.",
        },
        {
          q: "When is Full Disk Access needed?",
          a: "Only when your scripts read or modify files inside macOS protected folders (Desktop, Documents, Downloads, external volumes) without interactive prompts.",
        },
      ],
    },
    footer: {
      github: "GitHub",
      releases: "Releases",
      backToTop: "Top ↑",
    },
  },
  zh: {
    nav: {
      demo: "演示",
      features: "能力",
      scripting: "脚本",
      architecture: "架构",
      guide: "安装",
      faq: "问答",
      github: "GitHub",
      download: "下载",
    },
    hero: {
      title: "用纯脚本定制访达右键菜单。",
      ctaDownload: "下载 macOS 版",
      ctaGithub: "GitHub 源码",
      meta: "macOS 15+ · 通用二进制 · MIT",
    },
    demo: {
      sidebar: {
        favorites: "个人收藏",
        recents: "最近项目",
        applications: "应用程序",
        documents: "文稿",
        tags: "标签",
        work: "工作",
        personal: "个人",
      },
      menuItems: {
        openTerminal: "在终端中打开 — Ghostty",
        openEditor: "使用 Cursor 打开",
        copyPath: "复制路径",
        copyName: "复制文件名",
        compress: "打包压缩",
        convertWebp: "转换为 WebP",
        formatJson: "格式化 JSON",
      },
      toastFeedback: {
        openTerminal: "已在 Ghostty 打开 ~/Project-Assets",
        openEditor: "已使用 Cursor 打开",
        copyPath: "已复制 /Users/dev/Project-Assets",
        copyName: "已复制文件名",
        compress: "已生成压缩包 (exit 0)",
        convertWebp: "已转换为 WebP (exit 0)",
        formatJson: "已格式化 JSON (exit 0)",
      },
    },
    features: {
      items: [
        {
          id: "paths",
          title: "复制路径与文件名",
          desc: "支持单选与批量多选，直接复制完整绝对路径或纯文件名。",
        },
        {
          id: "terminals",
          title: "在终端中打开",
          desc: "支持 Ghostty、iTerm2、Warp、Alacritty、Kitty、系统终端或任意自定义终端。",
        },
        {
          id: "editors",
          title: "用编辑器打开",
          desc: "支持 VS Code、Cursor、Zed、Xcode、Sublime Text、JetBrains 及自定义应用。",
        },
        {
          id: "scripts",
          title: "Shell 与 AppleScript",
          desc: "通过原生 argv 数组（\"$@\"）传递路径，支持 .faaction 动作包导入与导出。",
        },
      ],
    },
    scripting: {
      title: "脚本与清单",
      tabScript: "compress.zsh",
      tabManifest: "manifest.json",
      tabOutput: "exec.jsonl",
      copyCode: "复制",
      copied: "已复制",
      pathCallout: "~/Library/Application Support/FinderActions/",
    },
    architecture: {
      title: "进程架构",
      hostTitle: "Host",
      hostMeta: "常驻 · <10 MB",
      hostDesc: "纯 AppKit 菜单栏进程，管理配置清单、后台执行脚本、记录日志并发布菜单快照。",
      settingsTitle: "Settings",
      settingsMeta: "按需启动 · SwiftUI",
      settingsDesc: "仅在编辑动作、测试输入或查看日志时启动，关闭窗口即退出释放内存。",
      syncTitle: "FinderSync",
      syncMeta: "沙盒扩展",
      syncDesc: "读取缓存快照渲染访达右键菜单，点击后将路径与动作 ID 转发给 Host。",
      compHeaders: ["指标", "FinderActions", "Electron / 传统常驻工具"],
      compRows: [
        { label: "常驻内存", fa: "< 10 MB", others: "150–400 MB" },
        { label: "闲置 CPU", fa: "0%", others: "后台轮询" },
        { label: "设置界面进程", fa: "关窗即退出", others: "后台常驻" },
        { label: "脚本存储", fa: "普通脚本文件 + JSON", others: "私有数据库" },
        { label: "网络请求", fa: "无", others: "遥测与授权校验" },
        { label: "开源许可", fa: "MIT", others: "闭源订阅" },
      ],
    },
    guide: {
      title: "安装",
      step1Title: "1. 移入 /Applications",
      step1Desc: "从 GitHub Releases 下载公证版 DMG 或 ZIP，将 FinderActions 拖入 /Applications。",
      downloadLink: "下载最新版本 ›",
      step2Title: "2. 启用访达扩展",
      step2Desc: "打开「系统设置 → 通用 → 登录项与扩展 → 访达」，开启 FinderActions。",
      step3Title: "3. 在访达中验证",
      step3Desc: "在访达中右键任意文件并运行「复制路径」，完成端到端验证。",
      troubleTitle: "重置 FinderSync 扩展注册（终端命令）",
      copyCmd: "复制",
      copiedCmd: "已复制",
    },
    faq: {
      title: "常见问题",
      items: [
        {
          q: "支持哪些 macOS 版本？",
          a: "支持 macOS 15 Sequoia 及更高版本（Apple Silicon 与 Intel 通用）。",
        },
        {
          q: "为什么 Host 进程不启用沙盒？",
          a: "沙盒进程无法直接调用 git、ffmpeg、jq 等命令行工具。Host 采用 Developer ID 签名与 Hardened Runtime 直接执行本地命令。",
        },
        {
          q: "可以使用 Python 或 Node.js 编写动作吗？",
          a: "可以。将动作的解释器设为 /usr/bin/python3、/opt/homebrew/bin/node 或任意可执行文件即可。",
        },
        {
          q: "包含空格或中文的路径如何传递？",
          a: "路径通过 Process 的 argv 参数数组逐项传入，不经过字符串拼接，脚本内直接遍历 \"$@\" 即可。",
        },
        {
          q: "何时需要授予完全磁盘访问权限？",
          a: "仅当脚本需要无弹窗读写桌面、文稿、下载或外置卷等受保护目录时才需要开启。",
        },
      ],
    },
    footer: {
      github: "GitHub",
      releases: "版本发布",
      backToTop: "顶部 ↑",
    },
  },
};

export const codeSnippets = {
  script: `#!/bin/zsh
set -euo pipefail

# "$@"           Selected paths (argv array)
# $FA_CWD        Working directory
# $FA_PATH_COUNT Number of selected items
# $FA_ACTION_ID  Action identifier

for f in "$@"; do
  out="\${f:t:r}.tar.gz"
  tar -czf "\${f:h}/$out" -C "\${f:h}" "\${f:t}"
done

print -r -- "Archived $# item(s)"`,

  manifest: compressActionManifest,

  output: `{"id":"9d4c2a","timestamp":"2026-11-06T14:10:02Z","actionId":"compress-archive","actionName":"Compress to Archive","success":true,"durationSeconds":0.18,"source":"finder","summary":"Archived 1 item(s)","paths":["/Users/dev/Project-Assets/hero-banner.png"]}`,
};
