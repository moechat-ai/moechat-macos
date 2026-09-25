import SwiftUI

/// 四象限。另有第 0 象限（时空），它不属于底部栏，由顶栏承担。
enum Quadrant: Int, CaseIterable, Identifiable {
    case first = 1
    case second
    case third
    case fourth

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .first: "肉体"
        case .second: "知识"
        case .third: "关系"
        case .fourth: "持有物"
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
            [SubApp(id: "body", title: "人体", symbol: "figure.stand")]
        case .second:
            [
                SubApp(id: "chat", title: "消息", symbol: "bubble.left"),
                SubApp(id: "stash", title: "收藏", symbol: "bookmark")
            ]
        case .third:
            [SubApp(id: "people", title: "人际", symbol: "person.2")]
        case .fourth:
            [SubApp(id: "wallet", title: "资产", symbol: "creditcard")]
        }
    }

    var defaultApp: SubApp { apps[0] }
}

/// 子应用。它是一个 Web 应用，跑在宿主的 WebAppContainer 里。
struct SubApp: Identifiable, Hashable {
    let id: String
    let title: String
    let symbol: String
}
