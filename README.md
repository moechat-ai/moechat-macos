# moechat-macos

[![CI](https://github.com/concordia-world/moechat-macos/actions/workflows/ci.yml/badge.svg)](https://github.com/concordia-world/moechat-macos/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/concordia-world/moechat-macos?color=blue)](https://github.com/concordia-world/moechat-macos/releases)

moechat 的 macOS 宿主（骨架）。

## 架构

**骨架原生，子应用 Web。**

- **宿主（本仓库）**：用 SwiftUI 实现骨架——顶栏、底栏、四个象限容器、主内容区
- **子应用**：Web 应用，跑在宿主的 WebView 里，各自独立成仓库（如 3D 人体、聊天）

「五端统一交互风格」靠**同一套设计规范**约束各端原生实现，而不是靠共享代码。框架层代码少，各端各写一遍可控；真正多、真正会漂移的是子应用，那部分统一到 Web。

## 已实现

- [x] 顶栏：主体图标（点击切换主体）、可输入的时空地址栏、后退 / 前进 / 刷新
- [x] 底栏：四个象限容器（肉体 / 知识 / 关系 / 持有物）
- [x] 点击容器原地放大 **3 倍**，露出 3×3 子应用网格，两侧容器被挤压让位
- [x] 点击容器的同时，该象限的**默认应用自动进入**
- [x] 点击网格中的子应用 → 进入
- [x] Web 子应用容器（WKWebView）＋ `moechat-app://` 本地源 ＋ 宿主↔子应用通信协议
- [x] 中英双语（宿主与子应用同时切换；系统菜单跟随系统）
- [ ] 主体切换面板
- [ ] 时空历史导航（后退 / 前进 / 刷新的语义）

## 运行

```sh
./scripts/make-app.sh          # 打包成 build/Moechat.app，同时把子应用产物拷进去
open build/Moechat.app
```

`swift run` 也能起，但**子应用会显示「未安装」**：子应用产物是从
`../msglist/dist` 拷进 `.app` 的 `Contents/Resources/apps/`，直跑二进制时没有这一步。
提示页会打印期望路径和应该跑的命令，不会白屏。

也可以用 Xcode 直接打开 `Package.swift`（Xcode 能原生打开 Swift Package）。

## 目录

```
Sources/Moechat/
├── MoechatApp.swift                     入口
├── i18n/Catalog.swift                   全部文案（类型化目录）+ 语言判定
├── Theme/Theme.swift                    统一视觉语言（五端共用一套取值）
├── Model/
│   ├── Quadrant.swift                   四象限 + 子应用定义（含文案键）
│   └── Subject.swift                    主体（用户）+ 时空坐标
├── WebBridge/
│   ├── HostContext.swift                宿主→子应用的上下文 / 子应用→宿主的消息
│   ├── SubAppScheme.swift               moechat-app:// 本地源（WKURLSchemeHandler）
│   └── WebAppContainer.swift            子应用容器（WKWebView + 注入 + 桥）
└── Shell/
    ├── RootView.swift                   骨架：顶栏 + 主内容区 + 底栏
    ├── TopBar.swift                     顶栏（第 0 象限：时空）
    ├── BottomBar.swift                  底栏（四个象限容器）
    └── QuadrantContainerView.swift      单个容器（收起态 / 放大 3 倍）
```

## 子应用

子应用是独立仓库的 Web 应用，宿主不内置其源码，只把它构建好的 `dist` 搬进 bundle。
当前接了 `msglist`（第二象限）。

**加载走 `moechat-app://<appId>/<相对路径>`**，不用 `file://`：
WKWebView 在 file:// 下把页面当不透明源，`<script type="module">` 会被 CORS 拒掉。
authority 用 appId 而不是固定值，是为了让每个子应用拿到**独立 origin**——
localStorage / IndexedDB / 缓存互不可见。

**改子应用之后要重新打包**（`./scripts/make-app.sh` 会把新的 dist 拷进去）。

## 多语言

宿主自己的文案在 `i18n/Catalog.swift`，是一个**类型化的 Swift 目录**：
`Catalog.zhHans` 是基准，`Catalog.en` 的类型就是 `Catalog`，所以漏翻一条、
多写一条、把字段名拼错都是**编译错误**。没有用 `Localizable.strings`——
那套机制下漏翻译只在运行时暴露成键名，没有任何东西拦得住。

系统菜单（文件 / 编辑 / 窗口 / 帮助）由 AppKit 自己产出，不归我们管，
只需在 `Info.plist` 里声明 `CFBundleLocalizations`，AppKit 按用户语言自己挑。

传给子应用的是**系统偏好语言的原样 BCP-47 标签**，不是宿主判定的结果。
两边按同一份规范各自兜底（`zh-Hans-CN → zh-Hans`，`en-US → en`，其余 → 简体）：
宿主不是子应用的语言权威，子应用要能脱离宿主独立决定。

本地验另一套语言（不动系统设置）：

```sh
build/Moechat.app/Contents/MacOS/Moechat -AppleLanguages '(en)'
```

## 关键约定

- 底栏四个象限容器，点击**原地放大为 3 倍**，两侧容器被挤压让位
- 点击容器的同时，该象限的**默认应用自动进入**，不需要在网格里再点一次
- 第 0 象限（时空）不占底栏，在顶栏；点击顶栏的主体图标切换主体
- 子应用归属于象限：例如「对话是第二象限与第三象限的交集，取第二象限」

## 注意

本仓库**必须放在本机文件系统上**。放在网络挂载卷（如 S3 挂载目录）下会导致 SwiftPM 卡死——构建在本地磁盘上是 6 秒，在网络卷上是无限等待。
