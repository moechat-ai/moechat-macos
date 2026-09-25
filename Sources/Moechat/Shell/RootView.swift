import SwiftUI

/// 宿主的骨架：顶栏（第 0 象限）＋ 主内容区（子应用）＋ 底栏（四个象限容器）。
struct RootView: View {
    @State private var subject: Subject = .sample
    @State private var address: SpacetimeAddress = .now
    @State private var expanded: Quadrant?
    @State private var activeApp: SubApp?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                TopBar(subject: subject, address: $address)

                contentArea

                BottomBar(expanded: $expanded, activeApp: $activeApp)
            }
        }
    }

    /// 子应用将来在这里以 Web 视图呈现。现在先显示当前所处的应用。
    private var contentArea: some View {
        ZStack {
            if let app = activeApp {
                VStack(spacing: 10) {
                    Image(systemName: app.symbol)
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(Theme.secondaryText)
                    Text(app.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.primaryText)
                    Text("Web 子应用将在此加载")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.faintText)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
