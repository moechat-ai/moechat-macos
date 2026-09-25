import SwiftUI

/// 四象限。另有第 0 象限（时空），它不属于底部栏，由顶栏承担。
enum Quadrant: Int, CaseIterable, Identifiable {
    case first = 1
    case second
    case third
    case fourth

    var id: Int { rawValue }

    /// 标题随语言变，所以存**键**不存成品字符串。取值用 `catalog[quadrant.titleKey]`。
    var titleKey: KeyPath<Catalog, String> {
        switch self {
        case .first: \.quadrantFirst
        case .second: \.quadrantSecond
        case .third: \.quadrantThird
        case .fourth: \.quadrantFourth
        }
    }

    var accent: Color {
        switch self {
        case .first: Color(hex: 0xE8794A)
        case .second: Color(hex: 0x3E9BD6)
        case .third: Color(hex: 0xD65BA6)
        case .fourth: Color(hex: 0xD9A441)
        }
    }

    /// 容器里的子应用。第一个是默认应用——点击容器直接进入它。
    var apps: [SubApp] {
        switch self {
        case .first:
            [SubApp(id: "body", title: \.appBody, symbol: "figure.stand")]
        case .second:
            [
                SubApp(id: "msglist", title: \.appMsglist, symbol: "bubble.left"),
                SubApp(id: "stash", title: \.appStash, symbol: "bookmark"),
            ]
        case .third:
            [SubApp(id: "people", title: \.appPeople, symbol: "person.2")]
        case .fourth:
            [SubApp(id: "wallet", title: \.appWallet, symbol: "creditcard")]
        }
    }

    var defaultApp: SubApp { apps[0] }
}

/// 子应用。它是一个 Web 应用，跑在宿主的 WebAppContainer 里。
struct SubApp: Identifiable, Hashable {
    /// 仓库名，同时是 `moechat-app://<id>/…` 的 authority。
    let id: String
    /// 文案键。不存成品字符串——语言是渲染期的事。
    let title: KeyPath<Catalog, String>
    let symbol: String
    /// 入口文件，相对该子应用自己的 origin。
    var entry: String = "index.html"

    /// 子应用由 id 唯一确定，文案键不参与相等性。
    static func == (lhs: SubApp, rhs: SubApp) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
