import compressActionManifest from './examples/compress-action.json?raw';

export const translations = {
  en: {
    nav: {
      demo: 'Demo',
      features: 'Capabilities',
      scripting: 'Scripts',
      architecture: 'Architecture',
      guide: 'Install',
      faq: 'FAQ',
      github: 'GitHub',
      download: 'Download',
    },
    hero: {
      title: 'Plain scripts in your Finder right-click menu',
      subhead: 'Copy paths, open folders in Ghostty or Cursor, and run Zsh or Python scripts with direct argv arrays',
      ctaDownload: 'Download for macOS',
      ctaGithub: 'Source on GitHub',
    },
    demo: {
      sidebar: {
        locations: 'Locations',
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
        copyName: 'Copied filename to clipboard',
        compress: 'Created hero-banner.tar.gz · exit 0',
        convertWebp: 'Converted hero-banner.webp · exit 0',
        formatJson: 'Formatted api-schema.json · exit 0',
      },
    },
    features: {
      title: 'What runs from a right-click',
      scriptsTitle: 'Shell and AppleScript actions',
      scriptsDesc: 'Every action is a local executable or inline script. Selected items arrive as separate Process argv elements rather than shell-interpolated strings, so spaces, quotes, and CJK paths never break.',
      pathsTitle: 'Copy Path and Filename',
      pathsDesc: 'Copies clean absolute paths or basenames for single and multi-file selections without holding Option',
      terminalsTitle: 'Open in Terminal',
      terminalsDesc: 'Launches your configured terminal directly in the selected directory',
      terminalsList: ['Ghostty', 'iTerm2', 'Warp', 'Alacritty', 'Kitty', 'Terminal'],
      editorsTitle: 'Open with Editor',
      editorsDesc: 'Adds one menu entry per enabled code editor or custom macOS app',
      editorsList: ['Cursor', 'VS Code', 'Zed', 'Xcode', 'Sublime Text', 'JetBrains'],
    },
    scripting: {
      title: 'Files on disk, ready for Git',
      desc: 'Configuration lives in a single JSON manifest next to plain scripts. Portable .faaction packages bundle an action and its scripts for sharing across Macs.',
      envTitle: 'Injected variables',
      envVars: [
        { key: '"$@"', note: 'Selected absolute paths' },
        { key: 'FA_CWD', note: 'Resolved working directory' },
        { key: 'FA_PATH_COUNT', note: 'Selected item count' },
        { key: 'FA_ACTION_ID', note: 'Manifest action identifier' },
      ],
      tabScript: 'compress.zsh',
      tabManifest: 'manifest.json',
      tabOutput: 'exec.jsonl',
      copyCode: 'Copy',
      copied: 'Copied',
      pathCallout: '~/Library/Application Support/FinderActions',
    },
    architecture: {
      title: 'Three processes, each doing one job',
      stats: [
        { label: 'Resident Host memory', value: '< 10 MB', note: 'vs 150–400 MB in Electron wrappers' },
        { label: 'Idle CPU usage', value: '0%', note: 'Event-driven via notifications' },
        { label: 'Settings process', value: '0 MB', note: 'Exits immediately when closed' },
      ],
      processes: [
        {
          name: 'FinderSync',
          role: 'Sandboxed extension',
          desc: 'Reads the cached menu snapshot, renders matching items in Finder, and forwards action IDs with selected paths',
        },
        {
          name: 'Host',
          role: 'AppKit menu-bar core',
          desc: 'Validates selection rules off the main thread, spawns scripts via Process, records JSONL logs, and publishes snapshots',
        },
        {
          name: 'Settings',
          role: 'On-demand SwiftUI helper',
          desc: 'Edits manifest rules, runs live file tests, and previews .faaction imports. Terminates on window close.',
        },
      ],
      compHeaders: ['Property', 'FinderActions', 'Electron / resident helpers'],
      compRows: [
        { label: 'Script storage', fa: 'Plain .zsh / .py + JSON', others: 'Opaque local or cloud database' },
        { label: 'Settings lifecycle', fa: 'Terminates on window close', others: 'Resident in background' },
        { label: 'Outbound network', fa: '0 requests', others: 'Telemetry and license checks' },
        { label: 'Source license', fa: 'MIT', others: 'Proprietary subscription' },
      ],
    },
    guide: {
      title: 'Install on macOS 15+',
      steps: [
        {
          num: '01',
          title: 'Move to /Applications',
          desc: 'Download the notarized DMG or ZIP from GitHub Releases and drag FinderActions into /Applications',
        },
        {
          num: '02',
          title: 'Enable the Finder extension',
          desc: 'Open System Settings → General → Login Items & Extensions → Finder and toggle FinderActions on',
        },
        {
          num: '03',
          title: 'Verify with Copy Path',
          desc: 'Right-click any file in Finder and choose Copy Path to confirm end-to-end execution',
        },
      ],
      downloadLink: 'Open latest release',
      troubleTitle: 'Re-register FinderSync from Terminal',
      copyCmd: 'Copy',
      copiedCmd: 'Copied',
    },
    faq: {
      title: 'Common questions',
      items: [
        {
          q: 'Which macOS versions are supported?',
          a: 'macOS 15 Sequoia and later, shipped as a Universal binary for Apple Silicon and Intel Macs.',
        },
        {
          q: 'Why is the Host process non-sandboxed?',
          a: 'A sandboxed app cannot invoke command-line tools like git, ffmpeg, jq, or Homebrew binaries without per-folder security-scoped bookmark prompts. Host is signed with Developer ID and Hardened Runtime.',
        },
        {
          q: 'Can actions use Python, Node, or Ruby?',
          a: 'Yes. Set the Shell interpreter field to /usr/bin/python3, /opt/homebrew/bin/node, or any executable binary on your Mac.',
        },
        {
          q: 'How are spaces and non-ASCII filenames passed?',
          a: 'Paths are passed directly as Process argv array entries rather than concatenated shell commands. Iterate over "$@" in Zsh or sys.argv[1:] in Python.',
        },
        {
          q: 'When is Full Disk Access needed?',
          a: 'Only when your scripts read or write inside macOS protected folders such as Desktop, Documents, Downloads, or external volumes without interactive prompts.',
        },
      ],
    },
    footer: {
      github: 'GitHub',
      releases: 'Releases',
      backToTop: 'Back to top',
    },
  },
  zh: {
    nav: {
      demo: '演示',
      features: '能力',
      scripting: '脚本',
      architecture: '架构',
      guide: '安装',
      faq: '问答',
      github: 'GitHub',
      download: '下载',
    },
    hero: {
      title: '把普通脚本放进访达右键菜单',
      subhead: '一键复制路径、在 Ghostty 或 Cursor 中打开目录，并以原生 argv 数组运行 Zsh 与 Python 脚本',
      ctaDownload: '下载 macOS 版',
      ctaGithub: 'GitHub 源码',
    },
    demo: {
      sidebar: {
        locations: '位置',
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
        copyName: '已复制文件名至剪贴板',
        compress: '已生成 hero-banner.tar.gz · exit 0',
        convertWebp: '已生成 hero-banner.webp · exit 0',
        formatJson: '已格式化 api-schema.json · exit 0',
      },
    },
    features: {
      title: '右键可触发的能力',
      scriptsTitle: 'Shell 与 AppleScript 脚本动作',
      scriptsDesc: '每个动作都是本地脚本或内联代码。所选路径以 Process 原生 argv 数组逐项传入，不做字符串拼接，天然兼容空格、引号与中文路径。',
      pathsTitle: '复制路径与文件名',
      pathsDesc: '无需按住 Option 键，支持单选与多选直接复制完整绝对路径或文件名',
      terminalsTitle: '在终端中打开',
      terminalsDesc: '直接在所选目录启动你配置的默认终端',
      terminalsList: ['Ghostty', 'iTerm2', 'Warp', 'Alacritty', 'Kitty', 'Terminal'],
      editorsTitle: '用编辑器打开',
      editorsDesc: '为每个已启用的代码编辑器或自定义应用生成独立菜单项',
      editorsList: ['Cursor', 'VS Code', 'Zed', 'Xcode', 'Sublime Text', 'JetBrains'],
    },
    scripting: {
      title: '纯文本落盘，直接纳入 Git 管理',
      desc: '配置保存在单一 JSON 清单中，与脚本文件并列存放。支持导出与预览导入 .faaction 单动作包，方便跨设备迁移。',
      envTitle: '注入变量',
      envVars: [
        { key: '"$@"', note: '所选文件绝对路径数组' },
        { key: 'FA_CWD', note: '解析后的工作目录' },
        { key: 'FA_PATH_COUNT', note: '所选项目数量' },
        { key: 'FA_ACTION_ID', note: '清单中的动作 ID' },
      ],
      tabScript: 'compress.zsh',
      tabManifest: 'manifest.json',
      tabOutput: 'exec.jsonl',
      copyCode: '复制',
      copied: '已复制',
      pathCallout: '~/Library/Application Support/FinderActions',
    },
    architecture: {
      title: '三个进程，各司其职',
      stats: [
        { label: '常驻 Host 内存', value: '< 10 MB', note: '对比 Electron 壳应用 150–400 MB' },
        { label: '闲置 CPU 占用', value: '0%', note: '完全由系统通知事件驱动' },
        { label: '设置界面常驻内存', value: '0 MB', note: '关闭设置窗口即彻底退出进程' },
      ],
      processes: [
        {
          name: 'FinderSync',
          role: '沙盒扩展',
          desc: '读取缓存快照渲染访达右键菜单，点击后将动作 ID 与所选路径转发至 Host',
        },
        {
          name: 'Host',
          role: 'AppKit 菜单栏核心',
          desc: '在后台线程校验匹配规则，通过 Process 执行脚本、写入 JSONL 日志并发布菜单快照',
        },
        {
          name: 'Settings',
          role: '按需 SwiftUI 进程',
          desc: '负责编辑动作规则、使用真实文件测试运行与预览导入 .faaction 包，关窗即退出',
        },
      ],
      compHeaders: ['维度', 'FinderActions', 'Electron / 常驻型工具'],
      compRows: [
        { label: '脚本存储方式', fa: '普通 .zsh / .py 文件 + JSON', others: '私有本地或云端数据库' },
        { label: '设置窗口生命周期', fa: '关闭窗口立即退出', others: '始终常驻后台' },
        { label: '外部网络请求', fa: '0 请求', others: '遥测上报与授权校验' },
        { label: '开源许可', fa: 'MIT', others: '闭源订阅制' },
      ],
    },
    guide: {
      title: '安装（macOS 15+）',
      steps: [
        {
          num: '01',
          title: '拖入 /Applications',
          desc: '从 GitHub Releases 下载经苹果公证的 DMG 或 ZIP，将 FinderActions 移入 /Applications',
        },
        {
          num: '02',
          title: '启用访达扩展',
          desc: '前往「系统设置 → 通用 → 登录项与扩展 → 访达」，开启 FinderActions 扩展',
        },
        {
          num: '03',
          title: '运行「复制路径」验证',
          desc: '在访达中右键任意文件并点击「复制路径」，完成端到端状态确认',
        },
      ],
      downloadLink: '前往最新发布页',
      troubleTitle: '在终端重新注册 FinderSync 扩展',
      copyCmd: '复制',
      copiedCmd: '已复制',
    },
    faq: {
      title: '常见问题',
      items: [
        {
          q: '支持哪些 macOS 版本？',
          a: '支持 macOS 15 Sequoia 及更高版本，提供 Apple Silicon 与 Intel 通用二进制包。',
        },
        {
          q: '为什么 Host 进程未启用沙盒？',
          a: '沙盒进程无法直接调用 git、ffmpeg、jq 或 Homebrew 工具链，否则需要逐目录弹出权限书签确认。Host 使用 Developer ID 与 Hardened Runtime 签名。',
        },
        {
          q: '可以使用 Python、Node.js 或 Ruby 吗？',
          a: '可以。将动作的解释器字段设为 /usr/bin/python3、/opt/homebrew/bin/node 或任意本地可执行文件路径即可。',
        },
        {
          q: '包含空格或中文的文件路径如何安全传递？',
          a: '路径通过 Process 的 argv 数组逐项传递，不经过 shell 字符串拼接。在 Zsh 中直接遍历 "$@"，或在 Python 中读取 sys.argv[1:]。',
        },
        {
          q: '什么情况下需要授予完全磁盘访问权限？',
          a: '仅当你的脚本需要无弹窗读写桌面、文稿、下载或外置卷等受保护目录时才需要开启。',
        },
      ],
    },
    footer: {
      github: 'GitHub',
      releases: '版本发布',
      backToTop: '返回顶部',
    },
  },
};

export const codeSnippets = {
  script: `#!/bin/zsh
set -euo pipefail

for f in "$@"; do
  out="\${f:t:r}.tar.gz"
  tar -czf "\${f:h}/$out" -C "\${f:h}" "\${f:t}"
done

print -r -- "Archived $# item(s)"`,

  manifest: compressActionManifest,

  output: `{"id":"9d4c2a","timestamp":"2026-11-07T04:10:02Z","actionId":"compress-archive","actionName":"Compress to Archive","success":true,"durationSeconds":0.18,"source":"finder","summary":"Archived 1 item(s)","paths":["/Users/dev/Project-Assets/hero-banner.png"]}`,
};
