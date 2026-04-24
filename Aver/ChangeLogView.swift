import SwiftUI
import WebKit

struct ChangeLogView: NSViewRepresentable {

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        // 右クリックコンテキストメニューを無効化
        let script = WKUserScript(
            source: "document.addEventListener('contextmenu', function(e){ e.preventDefault(); }, false);",
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(script)

        let webView = WKWebView(frame: .zero, configuration: config)

        let urlStr = "https://tama-san.com/app-page/assets/change-log/aver.html?\(UUID().uuidString)"
        if let url = URL(string: urlStr) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
