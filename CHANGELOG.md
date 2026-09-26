# 变更记录

本项目遵循 [语义化版本](https://semver.org/lang/zh-CN/)，格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)。

## [0.0.1] - 2026-09-26

首个版本。

### 新增

- 四象限底栏：肉体 / 知识 / 社会关系 / 持有物
- 子应用容器：`moechat-app://<appId>/<相对路径>` 本地源。authority 用 appId 是为了让每个子应用拿到**独立 origin**，localStorage / IndexedDB 互不可见
- 路径越界（`..` / 百分号编码 / 符号链接）一律拒绝并报错
- 中英双语。文案是类型化 Swift 目录，漏翻是编译错误；AppKit 系统菜单跟随系统语言
- 子应用未安装时给出提示页（缺什么 + 期望路径），不留白屏

### 说明

- **未经签名与公证**，首次打开需要右键 →「打开」
- 构建依赖 `moechat-ai/msglist` 的产物，CI 里会一并构建并放到同级目录
