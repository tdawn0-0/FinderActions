import compressActionManifest from './examples/compress-action.json?raw';

export const translations = {
  en: {
    nav: {
      how: 'How it works',
      features: 'Capabilities',
      compare: 'Compare',
      guide: 'Install',
      faq: 'FAQ',
      github: 'GitHub',
      download: 'Get FinderActions',
    },
    hero: {
      badgeNew: 'v1.0.4',
      badgeText: 'FinderActions 1.0.4: portable .faaction packages & live test',
      titleLead: 'Your Finder,',
      titleMuted: 'right-click',
      titleEnd: 'scripted.',
      lede: 'Right-click any file to copy its path, open it in Ghostty or Cursor, or run a plain shell script. No Electron, no accounts, no setup maze.',
      ctaPrimary: 'Download for Mac',
      ctaTry: 'Try it live',
      ctaGithub: 'Source on GitHub',
      metaLeft: 'Free & open source',
      metaMid: 'macOS 15 Sequoia or later',
      metaTag: 'MIT License',
    },
    demo: {
      menubarReady: '4 actions ready',
      sidebar: {
        favorites: 'Favorites',
        recents: 'Recents',
        applications: 'Applications',
        documents: 'Documents',
        tags: 'Tags',
        work: 'Work',
        personal: 'Personal',
      },
      itemCount: '5 items',
      menuItems: {
        openTerminal: 'Open in Terminal — Ghostty',
        openEditor: 'Open in Cursor',
        copyPath: 'Copy Path',
        copyName: 'Copy Filename',
        compress: 'Compress Archive',
        convertWebp: 'Convert to WebP',
        formatJson: 'Format JSON',
      },
      toastFeedback: {
        openTerminal: 'Opened Ghostty at ~/Project-Assets',
        openEditor: 'Opened in Cursor',
        copyPath: 'Copied /Users/dev/Project-Assets/hero-banner.png',
        copyName: 'Copied hero-banner.png to clipboard',
        compress: 'Created hero-banner.tar.gz (exit 0)',
        convertWebp: 'Converted hero-banner.webp (exit 0)',
        formatJson: 'Formatted api-schema.json (exit 0)',
      },
      caption: 'Click or right-click any file inside the MacBook screen to preview matching Finder actions.',
    },
    how: {
      eyebrow: 'How it works',
      titleDark: 'You write a plain script.',
      titleMuted: 'FinderActions puts it in the menu.',
      copy: 'Copy',
      copied: 'Copied',
      pathNote: '~/Library/Application Support/FinderActions',
      steps: [
        {
          num: '01',
          title: 'Write a .zsh, .py, or AppleScript',
          desc: 'Selected files arrive as separate Process argv elements ("$@"), so spaces, quotes, and Unicode filenames never break.',
          file: 'compress.zsh',
          tab: 'script' as const,
        },
        {
          num: '02',
          title: 'Set menu matching rules',
          desc: 'Filter by files, folders, single or multiple selection, and extensions like .png or .json in Settings or manifest.json.',
          file: 'manifest.json',
          tab: 'manifest' as const,
        },
        {
          num: '03',
          title: 'Test on real inputs & inspect logs',
          desc: 'Preview exact argv and FA_* variables before running, then inspect stdout, stderr, and duration in local JSONL logs.',
          file: 'exec.jsonl',
          tab: 'output' as const,
        },
        {
          num: '04',
          title: 'Share as a .faaction package',
          desc: 'Export an action with its scripts into one portable file. Imports preview the code first and start disabled until you turn them on.',
          file: 'compress.faaction',
          tab: 'package' as const,
        },
      ],
    },
    features: {
      eyebrow: 'Made to fit',
      titleDark: 'Your terminals, your editors,',
      titleMuted: 'your scripts.',
      cards: [
        {
          id: 'paths',
          title: 'Copy Path in one click',
          body: 'Copies clean absolute paths or basenames for one or multiple selected items without holding Option.',
        },
        {
          id: 'terminals',
          title: 'Open in your terminal',
          body: 'One menu entry opens Ghostty, iTerm2, Warp, Alacritty, Kitty, macOS Terminal, or any custom app at the target folder.',
        },
        {
          id: 'editors',
          title: 'Open with any code editor',
          body: 'Toggle Cursor, VS Code, Zed, Xcode, Sublime Text, JetBrains, or custom apps to add dedicated menu entries.',
        },
        {
          id: 'argv',
          title: 'Safe argv & FA_* environment',
          body: 'Passes "$@" plus FA_CWD, FA_PATHS, FA_PATH_COUNT, and FA_ACTION_ID directly via Process without shell interpolation.',
        },
        {
          id: 'packages',
          title: 'Portable .faaction packages',
          body: 'Bundle an action and its script files to move across Macs. Every import shows a source preview and starts disabled.',
        },
        {
          id: 'languages',
          title: 'Bilingual & theme-aware',
          body: 'Ships in English and Simplified Chinese, adapts natively to macOS Light and Dark appearances, and stays 100% offline.',
        },
      ],
    },
    compare: {
      eyebrow: 'Compare',
      titleDark: 'macOS has Quick Actions.',
      titleMuted: 'FinderActions keeps them fast and plain.',
      lede: 'Automator and Shortcuts wrap scripts inside proprietary workflows. Electron launchers stay resident at hundreds of megabytes. FinderActions pairs a tiny AppKit host with a thin FinderSync extension.',
      headers: ['Capability', 'FinderActions', 'Automator / Shortcuts', 'Sandboxed Menu Apps', 'Electron Launchers'],
      rows: [
        {
          topic: 'One-click Copy Path & Terminal',
          fa: { v: 'yes' as const, t: 'Built in from first launch' },
          mac: { v: 'some' as const, t: 'Manual workflow setup' },
          sbx: { v: 'yes' as const, t: 'Built in' },
          elec: { v: 'some' as const, t: 'Plugin required' },
        },
        {
          topic: 'Run git, ffmpeg, jq, Homebrew tools',
          fa: { v: 'yes' as const, t: 'Direct non-sandboxed Host' },
          mac: { v: 'some' as const, t: 'Full PATH often missing' },
          sbx: { v: 'no' as const, t: 'Blocked by sandbox bookmarks' },
          elec: { v: 'yes' as const, t: 'Direct execution' },
        },
        {
          topic: 'Script storage format',
          fa: { v: 'yes' as const, t: 'Plain .zsh / .py + JSON' },
          mac: { v: 'no' as const, t: 'Binary .workflow bundles' },
          sbx: { v: 'some' as const, t: 'App container database' },
          elec: { v: 'some' as const, t: 'Proprietary plugin store' },
        },
        {
          topic: 'Settings window memory when closed',
          fa: { v: 'yes' as const, t: '0 MB (process exits)' },
          mac: { v: 'yes' as const, t: '0 MB' },
          sbx: { v: 'no' as const, t: 'Stays in memory' },
          elec: { v: 'no' as const, t: '150–400 MB resident' },
        },
        {
          topic: 'Resident Host memory & idle CPU',
          fa: { v: 'yes' as const, t: '< 10 MB · 0% idle CPU' },
          mac: { v: 'yes' as const, t: 'System daemon' },
          sbx: { v: 'yes' as const, t: '~20–40 MB' },
          elec: { v: 'no' as const, t: '150–400 MB + background timers' },
        },
        {
          topic: 'Signed, notarized & open source',
          fa: { v: 'yes' as const, t: 'Apple notarized · MIT · Free' },
          mac: { v: 'yes' as const, t: 'Built into macOS' },
          sbx: { v: 'some' as const, t: 'Paid Mac App Store' },
          elec: { v: 'some' as const, t: 'Often subscription' },
        },
      ],
      footnote: 'Signed with Apple Developer ID and notarized by Apple. Zero outbound network requests, accounts, or telemetry.',
    },
    guide: {
      eyebrow: 'Get started',
      titleDark: 'Up and running',
      titleMuted: 'in three steps.',
      steps: [
        {
          num: '01',
          title: 'Move to /Applications',
          desc: 'Download the notarized DMG or ZIP from GitHub Releases and drag FinderActions into /Applications.',
        },
        {
          num: '02',
          title: 'Enable in System Settings',
          desc: 'Open System Settings → General → Login Items & Extensions → Finder and toggle FinderActions on.',
        },
        {
          num: '03',
          title: 'Verify with Copy Path',
          desc: 'Right-click any file in Finder and choose Copy Path to verify end-to-end setup.',
        },
      ],
      downloadLink: 'Download latest release',
      troubleSummary: 'Menu not showing right away on macOS Sequoia? Run the Terminal registration reset',
      copyCmd: 'Copy',
      copiedCmd: 'Copied',
    },
    faq: {
      eyebrow: 'FAQ',
      title: 'Frequently asked questions',
      note: 'Found a bug or want to inspect the source? Open an issue on GitHub.',
      githubIssues: 'GitHub Issues →',
      items: [
        {
          q: 'Which Macs does FinderActions work on?',
          a: 'Any Apple Silicon or Intel Mac running macOS 15 Sequoia or later.',
        },
        {
          q: 'Why is the Host process non-sandboxed?',
          a: 'Mac App Store sandboxing prevents invoking developer CLI tools like git, ffmpeg, jq, or Homebrew binaries without repetitive folder-permission bookmark prompts. FinderActions signs the Host with Apple Developer ID and Hardened Runtime and notarizes every release with Apple.',
        },
        {
          q: 'Can I write actions in Python, Node.js, or AppleScript?',
          a: 'Yes. Set the Shell interpreter field to /usr/bin/python3, /opt/homebrew/bin/node, or choose the AppleScript action type.',
        },
        {
          q: 'How are filenames with spaces, quotes, or Chinese characters handled?',
          a: 'Paths are passed as separate Process argv array entries rather than shell-concatenated strings. Iterate over "$@" in Zsh or sys.argv[1:] in Python.',
        },
        {
          q: 'Does it need Full Disk Access?',
          a: 'Only when your custom scripts read or write inside macOS protected folders (Desktop, Documents, Downloads, external drives) without interactive prompts.',
        },
        {
          q: 'Does FinderActions send any data anywhere?',
          a: 'No. Everything runs locally on your Mac. Neither Host, Settings, nor FinderSync makes network requests.',
        },
      ],
    },
    closing: {
      titleDark: 'Ready for a faster Finder?',
      sub: 'Every script, terminal, and editor one right-click away. Free forever under MIT.',
      cta: 'Download FinderActions',
      meta: 'Notarized by Apple · Universal binary · macOS 15 Sequoia or later',
    },
    footer: {
      github: 'GitHub',
      releases: 'Releases',
      docs: 'Install',
      backToTop: 'Back to top ↑',
    },
  },
  zh: {
    nav: {
      how: '工作原理',
      features: '核心能力',
      compare: '方案对比',
      guide: '安装上手',
      faq: '常见问题',
      github: 'GitHub',
      download: '免费下载',
    },
    hero: {
      badgeNew: 'v1.0.4',
      badgeText: 'FinderActions 1.0.4：支持 .faaction 便携包与真实文件测试',
      titleLead: '你的访达，',
      titleMuted: '右键动作',
      titleEnd: '随手脚本化。',
      lede: '在任意文件上轻点右键，即可复制绝对路径、在 Ghostty 或 Cursor 中打开目录，或直接运行本地 Shell 脚本。无 Electron、无账号、开箱即用。',
      ctaPrimary: '下载 macOS 版',
      ctaTry: '在线试玩',
      ctaGithub: 'GitHub 源码',
      metaLeft: '完全免费开源',
      metaMid: '支持 macOS 15 Sequoia 及以上',
      metaTag: 'MIT 许可',
    },
    demo: {
      menubarReady: '4 个动作已就绪',
      sidebar: {
        favorites: '个人收藏',
        recents: '最近项目',
        applications: '应用程序',
        documents: '文稿',
        tags: '标签',
        work: '工作',
        personal: '个人',
      },
      itemCount: '5 项',
      menuItems: {
        openTerminal: '在终端中打开 — Ghostty',
        openEditor: '使用 Cursor 打开',
        copyPath: '复制路径',
        copyName: '复制文件名',
        compress: '打包压缩',
        convertWebp: '转换为 WebP',
        formatJson: '格式化 JSON',
      },
      toastFeedback: {
        openTerminal: '已在 Ghostty 打开 ~/Project-Assets',
        openEditor: '已使用 Cursor 打开',
        copyPath: '已复制 /Users/dev/Project-Assets/hero-banner.png',
        copyName: '已复制文件名 hero-banner.png',
        compress: '已生成 hero-banner.tar.gz (exit 0)',
        convertWebp: '已转换为 hero-banner.webp (exit 0)',
        formatJson: '已格式化 api-schema.json (exit 0)',
      },
      caption: '在上方 MacBook 屏幕中点击（或右键）任意文件，实时体验访达右键规则匹配。',
    },
    how: {
      eyebrow: 'How it works',
      titleDark: '你只管写普通脚本，',
      titleMuted: '剩下的交给访达菜单。',
      copy: '复制',
      copied: '已复制',
      pathNote: '~/Library/Application Support/FinderActions',
      steps: [
        {
          num: '01',
          title: '编写普通 .zsh、.py 或 AppleScript',
          desc: '所选文件通过 Process 原生 argv 数组（"$@"）逐项传入，空格、引号与中文路径天然安全。',
          file: 'compress.zsh',
          tab: 'script' as const,
        },
        {
          num: '02',
          title: '配置菜单显示与扩展名规则',
          desc: '支持按文件/文件夹、单选/多选以及扩展名（如 .png、.json）精准控制右键菜单项显隐。',
          file: 'manifest.json',
          tab: 'manifest' as const,
        },
        {
          num: '03',
          title: '拖入真实文件测试并查看日志',
          desc: '在设置中直接预览完整 argv 与 FA_* 环境变量，运行后即时查看标准输出、错误输出与耗时记录。',
          file: 'exec.jsonl',
          tab: 'output' as const,
        },
        {
          num: '04',
          title: '导出分享 .faaction 便携包',
          desc: '将动作配置与脚本打包为单个文件跨 Mac 迁移；导入前先预览源码，默认以停用状态安全载入。',
          file: 'compress.faaction',
          tab: 'package' as const,
        },
      ],
    },
    features: {
      eyebrow: 'Made to fit',
      titleDark: '你的终端、你的编辑器、',
      titleMuted: '你的脚本习惯。',
      cards: [
        {
          id: 'paths',
          title: '一键复制干净路径',
          body: '无需按住 Option 键，单选或多选即可直接复制完整绝对路径或纯文件名。',
        },
        {
          id: 'terminals',
          title: '直达你顺手的终端',
          body: '支持 Ghostty、iTerm2、Warp、Alacritty、Kitty、系统终端或任意自定义应用，自动进入目标目录。',
        },
        {
          id: 'editors',
          title: '一键用常用编辑器打开',
          body: '勾选 Cursor、VS Code、Zed、Xcode、Sublime Text、JetBrains 或自定义应用即可生成对应菜单项。',
        },
        {
          id: 'argv',
          title: '原生 argv 与 FA_* 变量',
          body: '除 "$@" 外自动注入 FA_CWD、FA_PATHS、FA_PATH_COUNT 与 FA_ACTION_ID，绝不做危险的字符串拼接。',
        },
        {
          id: 'packages',
          title: '便携 .faaction 动作包',
          body: '单文件包含配置清单与脚本资产，导入时自动处理 ID 冲突并提供完整脚本源码预览。',
        },
        {
          id: 'languages',
          title: '中英双语 · 原生深浅色',
          body: '原生支持简体中文与英文界面，贴合 macOS 浅色与深色外观，全程离线零网络请求。',
        },
      ],
    },
    compare: {
      eyebrow: 'Compare',
      titleDark: '系统自带快速操作，',
      titleMuted: 'FinderActions 让它更快更纯粹。',
      lede: 'Automator 与快捷指令把脚本锁在私有工作流包中；Electron 启动器常驻动辄占用数百 MB 内存。FinderActions 用不到 10 MB 的纯原生 AppKit 进程配对极薄沙盒扩展。',
      headers: ['能力维度', 'FinderActions', 'Automator / 快捷指令', '沙盒右键工具', 'Electron 启动器'],
      rows: [
        {
          topic: '一键复制路径与打开终端',
          fa: { v: 'yes' as const, t: '开箱内置' },
          mac: { v: 'some' as const, t: '需手动拼装工作流' },
          sbx: { v: 'yes' as const, t: '内置' },
          elec: { v: 'some' as const, t: '需安装插件' },
        },
        {
          topic: '直接调用 git / ffmpeg / jq',
          fa: { v: 'yes' as const, t: '非沙盒 Host 直接执行' },
          mac: { v: 'some' as const, t: '常缺失 Homebrew 环境变量' },
          sbx: { v: 'no' as const, t: '受沙盒目录权限弹窗阻断' },
          elec: { v: 'yes' as const, t: '直接执行' },
        },
        {
          topic: '脚本存储与 Git 版本管理',
          fa: { v: 'yes' as const, t: '纯文本 .zsh / .py + JSON' },
          mac: { v: 'no' as const, t: '私有二进制 .workflow 包' },
          sbx: { v: 'some' as const, t: '封闭容器数据库' },
          elec: { v: 'some' as const, t: '专有插件目录' },
        },
        {
          topic: '关闭设置窗口后的界面内存',
          fa: { v: 'yes' as const, t: '0 MB（设置进程即刻退出）' },
          mac: { v: 'yes' as const, t: '0 MB' },
          sbx: { v: 'no' as const, t: '常驻后台内存' },
          elec: { v: 'no' as const, t: '常驻 150–400 MB' },
        },
        {
          topic: '常驻后台内存与闲置 CPU',
          fa: { v: 'yes' as const, t: '< 10 MB · 闲置 0% CPU' },
          mac: { v: 'yes' as const, t: '系统守护进程' },
          sbx: { v: 'yes' as const, t: '约 20–40 MB' },
          elec: { v: 'no' as const, t: '150–400 MB 且含后台轮询' },
        },
        {
          topic: '苹果公证与开源协议',
          fa: { v: 'yes' as const, t: 'Apple 公证 · MIT · 免费' },
          mac: { v: 'yes' as const, t: '系统内置' },
          sbx: { v: 'some' as const, t: '多为付费闭源' },
          elec: { v: 'some' as const, t: '多为按月订阅' },
        },
      ],
      footnote: '所有发布包均经 Apple Developer ID 签名并通过 Apple 公证。无账号、无遥测、零外部网络请求。',
    },
    guide: {
      eyebrow: 'Get started',
      titleDark: '三步完成配置，',
      titleMuted: '即刻投入日常使用。',
      steps: [
        {
          num: '01',
          title: '拖入 /Applications',
          desc: '下载经苹果公证的 DMG 或 ZIP 安装包，将 FinderActions 拖入 /Applications。',
        },
        {
          num: '02',
          title: '启用访达扩展',
          desc: '打开「系统设置 → 通用 → 登录项与扩展 → 访达」，开启 FinderActions 开关。',
        },
        {
          num: '03',
          title: '右键试运行「复制路径」',
          desc: '在访达中右键任意文件并点击「复制路径」，即可完成端到端激活验证。',
        },
      ],
      downloadLink: '前往最新版本下载页',
      troubleSummary: 'macOS Sequoia 启用扩展后菜单未立即出现？展开查看终端一键刷新命令',
      copyCmd: '复制',
      copiedCmd: '已复制',
    },
    faq: {
      eyebrow: 'FAQ',
      title: '常见问题',
      note: '遇到问题或想查看源码细节？欢迎直接在 GitHub 提交 Issue。',
      githubIssues: '前往 GitHub Issues →',
      items: [
        {
          q: '支持哪些 Mac 机型与系统版本？',
          a: '支持运行 macOS 15 Sequoia 及更高版本的所有 Apple Silicon 与 Intel Mac（通用二进制包）。',
        },
        {
          q: '为什么常驻 Host 进程没有启用沙盒？',
          a: 'Mac App Store 沙盒会阻止调用 git、ffmpeg、jq 或 Homebrew 等命令行工具，或者在每次访问新目录时反复弹出授权框。FinderActions 采用 Developer ID 签名、Hardened Runtime 与 Apple 官方公证，兼顾系统安全验证与无感执行。',
        },
        {
          q: '支持使用 Python、Node.js 或 AppleScript 编写动作吗？',
          a: '支持。在动作检查器中将解释器设为 /usr/bin/python3、/opt/homebrew/bin/node，或直接切换为 AppleScript 类型即可。',
        },
        {
          q: '文件名包含空格、单引号或中文字符会出错吗？',
          a: '不会。所有路径通过 Process 的 argv 参数数组逐个传入，绝不拼接 shell 命令字符串。在 Zsh 中遍历 "$@" 或在 Python 中读取 sys.argv[1:] 即可。',
        },
        {
          q: '必须授予「完全磁盘访问权限」吗？',
          a: '非必须。仅当你的自定义脚本需要无弹窗读写桌面、文稿、下载或外置硬盘等受保护目录时，才建议在系统设置中开启。',
        },
        {
          q: 'FinderActions 会联网或上传数据吗？',
          a: '完全不会。Host、Settings 与 FinderSync 均不包含任何联网或统计代码，所有配置与日志仅保存在本地。',
        },
      ],
    },
    closing: {
      titleDark: '准备好让访达右键更顺手了吗？',
      sub: '你的终端、编辑器与自动化脚本，只需一次右键。MIT 开源，永久免费。',
      cta: '免费下载 FinderActions',
      meta: 'Apple 官方公证 · 通用二进制 · 支持 macOS 15 Sequoia 及以上',
    },
    footer: {
      github: 'GitHub',
      releases: '版本发布',
      docs: '安装指南',
      backToTop: '回到顶部 ↑',
    },
  },
};

export const codeSnippets = {
  script: `#!/bin/zsh
set -euo pipefail

# "$@"           Selected absolute paths (argv array)
# $FA_CWD        Current Finder directory
# $FA_PATH_COUNT Number of selected items

for f in "$@"; do
  out="\${f:t:r}.tar.gz"
  tar -czf "\${f:h}/$out" -C "\${f:h}" "\${f:t}"
done

print -r -- "Archived $# item(s)"`,

  manifest: compressActionManifest,

  output: `{
  "id": "9d4c2a",
  "timestamp": "2026-11-07T04:10:02Z",
  "actionId": "compress-archive",
  "actionName": "Compress to Archive",
  "success": true,
  "durationSeconds": 0.18,
  "source": "finder",
  "summary": "Archived 1 item(s)",
  "paths": ["/Users/dev/Project-Assets/hero-banner.png"]
}`,

  package: `{
  "formatVersion": 1,
  "dependencies": "tar (macOS built-in)",
  "action": {
    "id": "compress-archive",
    "name": "Compress to Archive",
    "type": "shell",
    "enabled": false,
    "showWhen": "always"
  },
  "assets": {
    "compress.zsh": "#!/bin/zsh\\nset -euo pipefail..."
  }
}`,
};
