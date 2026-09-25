import SwiftUI
import WebKit

/// 子应用的宿主容器。
///
/// 子应用是 Web 应用（各自独立仓库），跑在这里。宿主与它之间靠两件事通信：
/// 1. 注入 `window.moechat` —— 子应用读取宿主上下文
/// 2. `window.moechatHost.post(type, payload)` —— 子应用向宿主发请求
struct WebAppContainer: NSViewRepresentable {
    let app: SubApp
    let context: HostContext
    let onMessage: (BridgeMessage) -> Void

    /// 容器里嵌的是 Web 内容，不是 SwiftUI 视图，语言得在这里定。
    @Environment(\.catalog) private var catalog

    func makeCoordinator() -> Coordinator {
        Coordinator(onMessage: onMessage)
    }

    func makeNSView(context ctx: Context) -> WKWebView {
        let controller = WKUserContentController()
        controller.add(ctx.coordinator, name: "moechat")
        controller.addUserScript(
            WKUserScript(
                source: Self.bootstrapScript(context),
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
        )

        let config = WKWebViewConfiguration()
        config.userContentController = controller
        // 子应用一律走 moechat-app:// 这个本地源，不留 file:// 后门。
        config.setURLSchemeHandler(SubAppSchemeHandler(), forURLScheme: SubAppSchemeHandler.scheme)

        let webView = WKWebView(frame: .zero, configuration: config)
        // 底色设成亮蓝只为诊断：如果画面变蓝，说明 WebView 活着但 HTML 没加载成功。
        webView.underPageBackgroundColor = NSColor(red: 0.12, green: 0.23, blue: 0.37, alpha: 1)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context ctx: Context) {
        // updateNSView 每次状态变化都会调，按 app.id 判断是否真要换页；
        // 否则切子应用时内容不更新，而输入框里每敲一个字都会重载页面。
        guard ctx.coordinator.loadedAppId != app.id else { return }
        ctx.coordinator.loadedAppId = app.id

        if SubAppSchemeHandler.isInstalled(app) {
            webView.load(URLRequest(url: SubAppSchemeHandler.url(for: app)))
        } else {
            // 明确说清缺什么、该放哪，不留白屏。
            webView.loadHTMLString(
                Self.missingHTML(
                    title: String(format: catalog.subappMissingTitle, app.id),
                    expected: String(
                        format: catalog.subappMissingExpected,
                        SubAppSchemeHandler.path(for: app)
                    ),
                    source: "\(SubAppSchemeHandler.scheme)://\(app.id)/\(app.entry)"
                ),
                baseURL: nil
            )
        }
    }

    /// 注入宿主上下文 + 通信函数。必须在 documentStart 执行——
    /// 子应用的模块脚本是 deferred，跑起来时 `window.moechat` 必须已经在。
    static func bootstrapScript(_ context: HostContext) -> String {
        let encoded = (try? JSONEncoder().encode(context))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        return """
        (function () {
          window.moechat = \(encoded);
          window.moechatHost = {
            post: function (type, payload) {
              window.webkit.messageHandlers.moechat.postMessage({
                type: type,
                payload: payload || {}
              });
            }
          };
        })();
        """
    }

    /// 子应用没装上时的提示页。
    private static func missingHTML(title: String, expected: String, source: String) -> String {
        """
        <!doctype html>
        <html><head><meta charset="utf-8">
        <style>
          html, body {
            margin: 0; height: 100%;
            background: #0A0B0D; color: rgba(255,255,255,.92);
            font: 13px/1.6 -apple-system, "PingFang SC", sans-serif;
            display: flex; align-items: center; justify-content: center;
          }
          .box { text-align: center; padding: 0 24px; }
          .sub { color: rgba(255,255,255,.38); font-size: 12px; margin-top: 8px;
                 overflow-wrap: anywhere; }
          code { font-family: ui-monospace, Menlo, monospace; color: #3E9BD6; }
        </style></head>
        <body>
          <div class="box">
            <div style="font-size:15px;font-weight:500;">\(title)</div>
            <div class="sub"><code>\(expected)</code></div>
            <div class="sub"><code>\(source)</code></div>
          </div>
        </body></html>
        """
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        let onMessage: (BridgeMessage) -> Void
        /// 已经载入的子应用 id。nil 表示还没载过。
        var loadedAppId: String?

        init(onMessage: @escaping (BridgeMessage) -> Void) {
            self.onMessage = onMessage
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard
                let body = message.body as? [String: Any],
                let type = body["type"] as? String
            else { return }

            let payload = body["payload"] as? [String: String]
            let decoded = BridgeMessage(type: type, payload: payload)
            Task { @MainActor in
                onMessage(decoded)
            }
        }
    }
}
