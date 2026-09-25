import SwiftUI

/// 宿主的骨架：顶栏（第 0 象限）＋ 主内容区（子应用）＋ 底栏（四个象限容器）。
struct RootView: View {
    /// 系统语言只在启动时解析一次：macOS 上换语言要重启 app。
    private let language = HostLanguage.current

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
        .environment(\.catalog, language.catalog)
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
    ///
    /// `locale` 给的是**系统偏好语言的原样 BCP-47 标签**，不是宿主自己判定的结果——
    /// 宿主不是子应用的语言权威，子应用要能脱离宿主独立决定（两边按同一份规范兜底，
    /// 见《设计规范》§4）。不一致就是规范有洞，不该靠一端替另一端擦屁股。
    private var hostContext: HostContext {
        HostContext(
            subjectId: subject.id,
            subjectName: subject.name,
            spacetime: address.text,
            theme: "dark",
            locale: language.tag
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
