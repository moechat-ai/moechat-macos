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

        let webView = WKWebView(frame: .zero, configuration: config)
        // 底色设成亮蓝只为诊断：如果画面变蓝，说明 WebView 活着但 HTML 没加载成功。
        webView.underPageBackgroundColor = NSColor(red: 0.12, green: 0.23, blue: 0.37, alpha: 1)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context ctx: Context) {
        // 在视图真正进入窗口后加载，makeNSView 阶段加载容易落空。
        guard !ctx.coordinator.hasLoaded else { return }
        ctx.coordinator.hasLoaded = true
        webView.loadHTMLString(Self.placeholderHTML(for: app), baseURL: nil)
    }

    /// 注入宿主上下文 + 通信函数。
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

    /// 子应用真正实现之前，先用这个占位页面验证通路。
    static func placeholderHTML(for app: SubApp) -> String {
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
          .box { text-align: center; }
          .sub { color: rgba(255,255,255,.38); font-size: 12px; margin-top: 6px; }
          code { font-family: ui-monospace, Menlo, monospace; color: #3E9BD6; }
        </style></head>
        <body>
          <div class="box">
            <div style="font-size:15px;font-weight:500;">\(app.title)</div>
            <div class="sub">Web 子应用占位 · 将由 <code>moechat-app-\(app.id)</code> 提供</div>
            <div class="sub" id="ctx" style="margin-top:14px;">宿主上下文读取中…</div>
          </div>
          <script>
            var c = window.moechat || {};
            document.getElementById('ctx').textContent =
              '主体 ' + (c.subjectName || '?') + ' · 时空 ' + (c.spacetime || '?') +
              ' · 主题 ' + (c.theme || '?');
          </script>
        </body></html>
        """
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        let onMessage: (BridgeMessage) -> Void
        var hasLoaded = false

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
