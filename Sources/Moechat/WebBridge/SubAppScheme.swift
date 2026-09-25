import Foundation
import WebKit

/// 子应用的本地源：`moechat-app://<appId>/<相对路径>`。
///
/// 为什么不用 `file://`：WKWebView 在 file:// 下把页面当不透明源，
/// `<script type="module">` 会被 CORS 拒掉，子应用直接不执行（Android 同理）。
///
/// 为什么 authority 是 appId 而不是固定值：这样子应用各自拿到**独立 origin**，
/// localStorage / IndexedDB / 缓存互不可见。共用一个 host 的话，将来任何一个
/// 子应用存了本地数据，就得回头改协议。Android 侧受 `WebViewAssetLoader` 限制
/// 共用了一个 host（见《设计方案》§11.1），macOS 没有理由跟着妥协。
final class SubAppSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "moechat-app"

    /// 子应用产物的根目录。
    ///
    /// `.app` 里是 `Contents/Resources/apps`（`scripts/make-app.sh` 负责把
    /// msglist 的 dist 拷进去）。`swift run` 直跑二进制时这里指向 .build 目录，
    /// 找不到子应用——那时子应用容器显示「未安装」并打印期望路径，
    /// 而不是白屏。
    static var appsRoot: URL {
        (Bundle.main.resourceURL ?? Bundle.main.bundleURL)
            .appending(path: "apps", directoryHint: .isDirectory)
    }

    /// 子应用的入口 URL。入口文件相对该子应用自己的 origin。
    static func url(for app: SubApp) -> URL {
        URL(string: "\(scheme)://\(app.id)/\(app.entry)")!
    }

    /// 磁盘上该子应用入口的实际路径。只用于「未安装」提示。
    static func path(for app: SubApp) -> String {
        appsRoot.appending(path: app.id).appending(path: app.entry).path
    }

    /// 子应用是否已安装 = 入口文件在不在。
    static func isInstalled(_ app: SubApp) -> Bool {
        FileManager.default.fileExists(atPath: path(for: app))
    }

    private let root: URL

    init(appsRoot: URL = SubAppSchemeHandler.appsRoot) {
        self.root = appsRoot.standardizedFileURL
        super.init()
    }

    // MARK: - WKURLSchemeHandler

    func webView(_ webView: WKWebView, start urlSchemeTask: any WKURLSchemeTask) {
        do {
            guard let url = urlSchemeTask.request.url else {
                throw SchemeError.malformedURL("(request.url 为 nil)")
            }
            let (data, mime) = try load(url)
            let response = URLResponse(
                url: url,
                mimeType: mime,
                expectedContentLength: data.count,
                textEncodingName: nil
            )
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(data)
            urlSchemeTask.didFinish()
        } catch {
            // 读失败就交给 WebKit 报出来（控制台可见、该资源加载失败），不吞。
            // 这里不适合让异常炸掉进程：少了 favicon 不该拖垮宿主。
            urlSchemeTask.didFailWithError(error)
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: any WKURLSchemeTask) {
        // 读盘是同步的，stop 到达时该 task 早已完成，没有可取消的动作。
    }

    // MARK: - 取文件

    private func load(_ url: URL) throws -> (Data, String) {
        let target = try resolve(url)
        guard let data = FileManager.default.contents(atPath: target.path) else {
            throw SchemeError.notFound(target.path)
        }
        return (data, Self.mimeType(for: target.pathExtension))
    }

    /// URL → 磁盘路径。任何越出子应用根目录的路径直接拒掉。
    private func resolve(_ url: URL) throws -> URL {
        guard let appId = url.host, !appId.isEmpty, appId != ".", appId != ".." else {
            throw SchemeError.badAppId(url.absoluteString)
        }
        let segments = url.path.split(separator: "/").map(String.init)
        // `..` 必须在归一化**之前**拦：`/a/../../x` 归一化后落在根外才被发现，
        // 那时已经来不及分辨是恶意还是笔误。
        guard !segments.contains("..") else { throw SchemeError.illegalPath(url.path) }

        let appRoot = root.appending(path: appId, directoryHint: .isDirectory)
        let target = (segments.isEmpty
            ? appRoot.appending(path: "index.html")
            : appRoot.appending(path: segments.joined(separator: "/"))
        ).standardizedFileURL

        // 归一化后再确认一次：拦掉百分号编码与符号链接的绕过。
        guard target.path.hasPrefix(appRoot.path + "/") else {
            throw SchemeError.illegalPath(url.path)
        }
        return target
    }

    /// 模块脚本对 MIME 敏感：`text/javascript` 不对的话浏览器直接拒绝执行。
    private static func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "html", "htm": "text/html"
        case "js", "mjs": "text/javascript"
        case "css": "text/css"
        case "json", "map": "application/json"
        case "svg": "image/svg+xml"
        case "png": "image/png"
        case "jpg", "jpeg": "image/jpeg"
        case "gif": "image/gif"
        case "webp": "image/webp"
        case "ico": "image/x-icon"
        case "woff2": "font/woff2"
        case "woff": "font/woff"
        case "ttf": "font/ttf"
        case "txt": "text/plain"
        default: "application/octet-stream"
        }
    }
}

enum SchemeError: LocalizedError {
    case malformedURL(String)
    case badAppId(String)
    case illegalPath(String)
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .malformedURL(let raw):
            "子应用 URL 无法解析：\(raw)"
        case .badAppId(let raw):
            "子应用 URL 缺少 appId：\(raw)"
        case .illegalPath(let path):
            "子应用路径越界：\(path)"
        case .notFound(let path):
            "子应用资源不存在：\(path)"
        }
    }
}
