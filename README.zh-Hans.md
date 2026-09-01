# FinderActions

开源的 macOS **Finder 自定义右键菜单**。

**架构（方案 B）：** 非沙盒 **Host**（菜单栏）是唯一执行器；**极薄 FinderSync** 只负责展示菜单快照并转发点击。无 Runner 进程、无 security-scoped 书签链路、无遥测、无内购。

> 一句话：Finder 右键脚本启动器 — 脚本即插件，可编辑、可 git、可分享。

## 环境要求

- macOS 15+
- 构建需 Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)（`brew install xcodegen`）
- 发布需加入 Apple Developer Program

## 开发

```bash
./Scripts/dev.sh   # 生成工程并构建 Debug
./Scripts/test.sh  # 运行 Swift 测试
```

`dev.sh` 根据 `project.yml` 生成 `FinderActions.xcodeproj`，因此 YAML 是工程配置的唯一事实来源。之后也可以用 Xcode 打开工程并运行 **FinderActions** scheme。

## Mac App Store 之外发布

发布流程使用 Developer ID 签名、Hardened Runtime、Apple 公证、票据装订和 Gatekeeper 验证。

```bash
./Scripts/setup-signing.sh  # 每台开发 Mac 只需执行一次
./Scripts/release.sh        # 生成已测试、签名、公证的发布 ZIP
```

产物位于 `build/releases/`。凭据配置、流水线细节及故障排查见 [docs/releasing.md](docs/releasing.md)。

建议把生成的 `FinderActions.app` 放到 `/Applications`，便于扩展注册。

### 无界面检查

```bash
./build/DerivedData/Debug/Build/Products/Debug/FinderActions.app/Contents/MacOS/FinderActions --dump-actions
```

### 单元测试与 Shell 路径 harness

```bash
swift test
swift run ShellExecHarness /tmp/shell-exec.log
```

## 启用 Finder 扩展

1. 启动 **FinderActions**（菜单栏锤子图标）。
2. **系统设置 → 隐私与安全性 → 扩展 → 已添加的扩展**（不同系统版本文案可能不同），启用 FinderActions。
3. 在 Finder 中右键文件/文件夹。

### 菜单不出现时（Sequoia+）

```bash
pluginkit -a "/Applications/FinderActions.app/Contents/PlugIns/FAFinderSync.appex"
pluginkit -e use -i com.finderactions.host.FinderSync
pluginkit -m -i com.finderactions.host.FinderSync
killall Finder
```

Host 的 **扩展** 页也可打开系统设置、重启 Finder。

## 默认动作与应用程序

默认只启用少量项，避免菜单膨胀：

| 动作 | 类型 |
|------|------|
| 在终端中打开 | 选中的终端 |
| 复制路径 | `shell` |
| 复制文件名 | `shell` |
| 用 Visual Studio Code 打开 | 选中的编辑器 |

在 **设置 → Applications** 中选择一个终端，以及一个或多个编辑器。
Finder 始终只显示一个通用的“在终端中打开”；每个已选编辑器各显示一个菜单项。
内置目录覆盖常见终端与编辑器，也可以通过“选择应用程序…”添加任意 macOS `.app`。

## 编写 Shell 动作

脚本目录：

```
~/Library/Application Support/FinderActions/Actions/
```

清单：

```
~/Library/Application Support/FinderActions/manifest.json
```

脚本环境变量：

| 变量 | 含义 |
|------|------|
| `"$@"` | 选中路径列表（空格/中文/`'`/`$` 安全） |
| `FA_CWD` | Finder 当前目录 |
| `FA_PATHS` | 换行分隔路径 |
| `FA_PATH_COUNT` | 数量 |
| `FA_CONTAINER` | 容器路径 |
| `FA_ACTION_ID` | 动作 id |

详见 [docs/scripting.md](docs/scripting.md)。

## 架构

```
Host（非沙盒）                 FinderSync（沙盒、极薄）
  配置 / 脚本 / 日志     ←→      只渲染快照菜单
  执行 app/shell/终端            只转发 actionId + 路径
  发布菜单快照                   不跑 Process / 脚本
```

## 隐私

- 无遥测、无账号、Host 不发起业务网络请求  
- 扩展不读文件内容、不上传  
- 日志仅本地，可一键清空  

## 许可证

MIT — 见 [LICENSE](LICENSE)。
