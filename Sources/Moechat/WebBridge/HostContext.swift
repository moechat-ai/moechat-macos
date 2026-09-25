import Foundation

/// 宿主向子应用暴露的上下文。
/// 子应用启动时会读到它——这是「宿主 tells 子应用」的那一半协议。
struct HostContext: Codable {
    var subjectId: String
    var subjectName: String
    /// 当前时空坐标，格式与地址栏一致。
    var spacetime: String
    /// 主题。目前只有 dark，为将来留口子。
    var theme: String
    var locale: String
}

/// 子应用向宿主发的消息 —— 这是协议的另一半。
struct BridgeMessage: Decodable {
    let type: String
    let payload: [String: String]?

    enum Kind: String {
        case navigate   // 跳转到另一个时空
        case openApp    // 打开另一个子应用
        case log        // 写一条日志
        case close      // 收起当前子应用
        case unknown
    }

    var kind: Kind { Kind(rawValue: type) ?? .unknown }
}
