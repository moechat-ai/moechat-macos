import Foundation

/// 主体 = 用户。产品支持登录与切换多个主体。
struct Subject: Identifiable, Hashable {
    let id: String
    var name: String
    var initial: String

    static let sample = Subject(id: "1", name: "李鹏", initial: "李")
}

/// 时空坐标。顶栏地址栏里显示并允许输入的就是它。
struct SpacetimeAddress: Equatable {
    var year: Int
    var month: Int
    var day: Int
    var longitude: Double
    var latitude: Double

    var text: String {
        "\(year)&\(month)&\(day),\(longitude),\(latitude)"
    }

    static let now = SpacetimeAddress(
        year: 2026, month: 9, day: 25,
        longitude: 116.3974, latitude: 39.9093
    )
}
