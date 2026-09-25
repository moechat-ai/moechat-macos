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

    /// 子应用以 Web 视图呈现，各子应用是独立的 Web 仓库。
    private var contentArea: some View {
        ZStack {
            if let app = activeApp {
                WebAppContainer(
                    app: app,
                    context: hostContext,
                    onMessage: handleBridgeMessage
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 宿主交给子应用的上下文。
    private var hostContext: HostContext {
        HostContext(
            subjectId: subject.id,
            subjectName: subject.name,
            spacetime: address.text,
            theme: "dark",
            locale: "zh-Hans"
        )
    }

    /// 子应用发回来的请求。
    private func handleBridgeMessage(_ message: BridgeMessage) {
        switch message.kind {
        case .navigate:
            // TODO: 解析 message.payload["address"] 并跳转
            break
        case .openApp:
            // TODO: 按 payload["id"] 找到子应用并切换
            break
        case .log:
            // TODO: 写入主体日志
            break
        case .close:
            activeApp = nil
            expanded = nil
        case .unknown:
            break
        }
    }
}
