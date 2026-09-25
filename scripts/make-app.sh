#!/bin/sh
# 把 SwiftPM 构建出的可执行文件打包成 macOS .app bundle。
#
# 为什么需要它：SwiftPM 直接产出的可执行文件不是 .app，缺少 Info.plist，
# macOS 的 GUI 生命周期（NSApplication）起不来，跑一下就退出。
#
# 用法：
#   ./scripts/make-app.sh          # debug
#   ./scripts/make-app.sh release

set -e

CONFIG="${1:-debug}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/build/Moechat.app"

cd "$ROOT"

# 注意：`swift build --show-bin-path` 只打印路径、不触发构建。
# 必须显式构建一次，否则会打包到上一次的旧二进制。
swift build -c "$CONFIG"
BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path)"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/Moechat" "$APP/Contents/MacOS/Moechat"

# 子应用产物。宿主不内置子应用源码，只把它构建好的 dist 搬进来——与 Android 侧
# 的 syncSubApps 同一策略。缺了就直接报错退出并说清该跑哪条命令，
# 不留「打开是 404」这种无头绪的失败。
MSGSLIST_DIST="$ROOT/../msglist/dist"
if [ ! -d "$MSGSLIST_DIST" ]; then
    echo "错误：子应用 msglist 未构建：$MSGSLIST_DIST 不存在" >&2
    echo "先在 ${MSGSLIST_DIST%/dist} 执行：npm install && npm run build" >&2
    exit 1
fi
mkdir -p "$APP/Contents/Resources/apps"
cp -R "$MSGSLIST_DIST" "$APP/Contents/Resources/apps/msglist"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Moechat</string>
    <key>CFBundleDisplayName</key><string>moechat</string>
    <key>CFBundleIdentifier</key><string>ai.moechat.macos</string>
    <key>CFBundleExecutable</key><string>Moechat</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
    <!-- 宿主自己的文案在本包里是类型化的 Swift 目录（见 i18n/Catalog.swift），
         不用 .lproj。但 AppKit 自己产出的系统菜单（文件 / 编辑 / 窗口 / 帮助）
         由系统提供，要让它按用户语言挑，必须在 bundle 里声明支持哪些语言。 -->
    <key>CFBundleDevelopmentRegion</key><string>zh-Hans</string>
    <key>CFBundleLocalizations</key>
    <array>
        <string>zh-Hans</string>
        <string>en</string>
    </array>
</dict>
</plist>
PLIST

echo "已生成 $APP"
