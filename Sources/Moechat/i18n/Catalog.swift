import Foundation
import SwiftUI

/// 宿主全部文案。字段名即键，值是文案。
///
/// 基准语言是 zh-Hans，其余语言的类型就是 `Catalog` 本身——所以漏翻一条、
/// 多写一条、把字段名拼错，**全都是编译错误**。
///
/// 为什么不用 `Localizable.strings`：那套机制下漏翻译只在运行时暴露成键名
/// （界面直接显示 `quadrantThird`），没有任何东西拦得住「搬走了但没翻」。
/// 本项目的硬要求是删除 hardcode，`.strings` 只做到搬走。子应用侧用的是
/// 同一套保证（类型化 TS 目录），宿主没理由退回弱保证。详见《设计方案》§11.2。
struct Catalog: Sendable {
    // 象限
    var quadrantFirst: String
    var quadrantSecond: String
    var quadrantThird: String
    var quadrantFourth: String

    // 子应用
    var appBody: String
    var appMsglist: String
    var appStash: String
    var appPeople: String
    var appWallet: String

    // 顶栏
    var topbarAddressPlaceholder: String
    var topbarSwitchSubject: String
    var topbarBack: String
    var topbarForward: String
    var topbarReload: String

    // 子应用加载不出来时的提示。`%@` 由 String(format:) 填。
    var subappMissingTitle: String
    var subappMissingExpected: String
}

extension Catalog {
    /// 基准语言。系统语言不在支持列表里时回落到它。
    static let zhHans = Catalog(
        quadrantFirst: "肉体",
        quadrantSecond: "知识",
        quadrantThird: "关系",
        quadrantFourth: "持有物",

        appBody: "人体",
        appMsglist: "消息",
        appStash: "收藏",
        appPeople: "社会关系",
        appWallet: "资产",

        topbarAddressPlaceholder: "时空坐标",
        topbarSwitchSubject: "切换主体",
        topbarBack: "后退",
        topbarForward: "前进",
        topbarReload: "刷新",

        subappMissingTitle: "子应用「%@」未安装",
        subappMissingExpected: "期望资源：%@"
    )

    /// 英文。类型是 `Catalog`，所以它与基准的字段必须逐一对应。
    static let en = Catalog(
        quadrantFirst: "Body",
        quadrantSecond: "Knowledge",
        quadrantThird: "Relations",
        quadrantFourth: "Possessions",

        appBody: "Physique",
        appMsglist: "Messages",
        appStash: "Saved",
        appPeople: "Social",
        appWallet: "Assets",

        topbarAddressPlaceholder: "Spacetime address",
        topbarSwitchSubject: "Switch subject",
        topbarBack: "Back",
        topbarForward: "Forward",
        topbarReload: "Reload",

        subappMissingTitle: "Sub-app “%@” is not installed",
        subappMissingExpected: "Expected resource: %@"
    )

    /// 支持的语言，按小写 BCP-47 标签索引。新增语言只加这一行。
    static let byTag: [String: Catalog] = [
        "zh-hans": .zhHans,
        "en": .en,
    ]

    /// 系统偏好语言 → 目录。
    ///
    /// 兜底链与子应用侧 `resolveTag` 完全一致（《设计规范》§4）：
    ///
    ///     zh-Hans-CN → zh-Hans        命中
    ///     zh-CN      → zh → 未命中     → 基准（简体）
    ///     en-US      → en             命中
    ///     fr-FR      → 未命中          → 基准
    static func resolve(preferredLanguages: [String]) -> Catalog {
        for tag in preferredLanguages {
            // 系统给的标签可能是 `zh_Hans_CN`（下划线），归一到 BCP-47。
            let parts = tag
                .replacingOccurrences(of: "_", with: "-")
                .split(separator: "-")
                .map(String.init)
            for length in stride(from: parts.count, through: 1, by: -1) {
                let candidate = parts.prefix(length).joined(separator: "-").lowercased()
                if let hit = byTag[candidate] { return hit }
            }
        }
        return .zhHans
    }

    /// 取文案。视图只认键，语言在渲染期定。
    subscript(titleKey: KeyPath<Catalog, String>) -> String { self[keyPath: titleKey] }
}

/// 宿主当前的语言。
///
/// macOS 上换系统语言要重启 app，所以只在启动时解析一次，不做运行时切换。
struct HostLanguage {
    /// 原样的系统偏好语言标签（BCP-47），交给子应用。
    let tag: String
    /// 宿主自己渲染用的目录。
    let catalog: Catalog

    static let current: HostLanguage = {
        let preferred = Locale.preferredLanguages
        return HostLanguage(
            tag: preferred.first ?? "zh-Hans",
            catalog: Catalog.resolve(preferredLanguages: preferred)
        )
    }()
}

private struct CatalogKey: EnvironmentKey {
    static let defaultValue = Catalog.zhHans
}

extension EnvironmentValues {
    /// 当前语言目录。视图一律从这里取文案，不直接读 `HostLanguage.current`——
    /// 那样视图就没法在没有系统偏好的环境里测。
    var catalog: Catalog {
        get { self[CatalogKey.self] }
        set { self[CatalogKey.self] = newValue }
    }
}
