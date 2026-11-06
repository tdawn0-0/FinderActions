# FinderActions

开源的 macOS **Finder 自定义右键菜单**。

**架构：** 非沙盒 **Host** 是仅含 AppKit 的轻量常驻执行器；SwiftUI **Settings helper** 按需启动、窗口关闭即退出；**极薄 FinderSync** 只负责展示菜单快照并转发点击。无 Runner 进程、security-scoped 书签链路、遥测或内购。

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
构建还会强制检查 Host 二进制没有链接 SwiftUI。

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

详见 [docs/architecture.md](docs/architecture.md)、[docs/ipc.md](docs/ipc.md)、[docs/scripting.md](docs/scripting.md)、[docs/troubleshooting.md](docs/troubleshooting.md) 与 [docs/releasing.zh-Hans.md](docs/releasing.zh-Hans.md)（打包公证与网站部署）。

## 创建自己的 Finder 工作流程

- 从逐个处理文件、当前目录命令、打开应用或空白脚本模板创建动作。
  新动作默认停用，配置完成后再启用。
- 设置文件扩展名及文件／文件夹条件，让右键菜单只显示适用的动作。
- 选择或拖入真实测试输入，检查执行预览，再手动运行测试。
  测试会真实执行脚本，可能更改文件。
- 首次引导会带你在访达中成功执行一次“复制路径”。界面分别显示
  扩展已注册、已启用和已验证执行，避免把注册状态当作使用成功。
- 菜单栏显示正在运行的 Finder 任务；最近活动包含动作名称、文件数量和耗时。
  点击结果可查看日志，再进入对应动作编辑。通知可设为每次完成、仅失败或关闭。
- 将单个动作及其脚本导出为本地 `.faaction` 文件。导入前可预览脚本和依赖说明；
  导入后生成新标识符，并保持停用，等待你检查和启用。

详细行为及动作包限制见 [脚本指南](docs/scripting.md)。
[工作流程验证](docs/troubleshooting.md#verify-the-six-workflows)提供了可执行检查步骤。
Live Test 运行期间，设置窗口会保持打开。

## 架构

```
Settings helper（SwiftUI，关窗即退出）
              │ 保存配置 + 通知 Host 重载
              ▼
Host（AppKit、非沙盒）          FinderSync（沙盒、极薄）
  配置 / 脚本 / 日志       ←→      只渲染快照菜单
  执行 app/shell/终端              只转发 actionId + 路径
  发布菜单快照                     不跑 Process / 脚本
```

## 隐私

- 无遥测、无账号、Host 不发起业务网络请求  
- 扩展不读文件内容、不上传  
- 日志仅本地，可一键清空  

## 许可证

MIT — 见 [LICENSE](LICENSE)。
