import SwiftUI
import WebKit
import ComposableArchitecture

/// UIViewRepresentable wrapping WKWebView for browser content display.
struct WebContentView: UIViewRepresentable {
    let tab: BrowserTab
    let findQuery: String
    let store: StoreOf<ResearchBrowserFeature>

    // Signals that the coordinator should respond to
    let goBackSignal: Bool
    let goForwardSignal: Bool
    let reloadSignal: Bool

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        // JS injection to extract selected text on demand
        let selectionScript = WKUserScript(
            source: """
            window.__getSelectedText = function() {
                return window.getSelection().toString();
            };
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(selectionScript)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = .systemBackground

        // Observe estimated progress
        context.coordinator.progressObservation = webView.observe(\.estimatedProgress, options: .new) { wv, _ in
            Task { @MainActor in
                store.send(.webViewProgressChanged(tabID: tab.id, progress: wv.estimatedProgress))
            }
        }

        // Observe title
        context.coordinator.titleObservation = webView.observe(\.title, options: .new) { wv, _ in
            if let title = wv.title, !title.isEmpty {
                Task { @MainActor in
                    store.send(.webViewTitleChanged(tabID: tab.id, title: title))
                }
            }
        }

        // Load initial URL
        let request = URLRequest(url: tab.url)
        webView.load(request)

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let coordinator = context.coordinator

        // Navigate to a new URL if it changed
        if tab.url != coordinator.currentURL {
            coordinator.currentURL = tab.url
            let request = URLRequest(url: tab.url)
            webView.load(request)
        }

        // Go back
        if goBackSignal != coordinator.lastGoBackSignal {
            coordinator.lastGoBackSignal = goBackSignal
            if webView.canGoBack {
                webView.goBack()
            }
        }

        // Go forward
        if goForwardSignal != coordinator.lastGoForwardSignal {
            coordinator.lastGoForwardSignal = goForwardSignal
            if webView.canGoForward {
                webView.goForward()
            }
        }

        // Reload
        if reloadSignal != coordinator.lastReloadSignal {
            coordinator.lastReloadSignal = reloadSignal
            webView.reload()
        }

        // Find in page
        if findQuery != coordinator.lastFindQuery {
            coordinator.lastFindQuery = findQuery
            if findQuery.isEmpty {
                // Clear highlights
                webView.evaluateJavaScript(
                    "window.getSelection().removeAllRanges();",
                    completionHandler: nil
                )
            } else {
                let escaped = findQuery
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "'", with: "\\'")
                webView.evaluateJavaScript(
                    "window.find('\(escaped)', false, false, true, false, true, false);",
                    completionHandler: nil
                )
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(tab: tab, store: store)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate {
        let tabID: UUID
        let store: StoreOf<ResearchBrowserFeature>

        var currentURL: URL
        var lastGoBackSignal: Bool = false
        var lastGoForwardSignal: Bool = false
        var lastReloadSignal: Bool = false
        var lastFindQuery: String = ""

        var progressObservation: NSKeyValueObservation?
        var titleObservation: NSKeyValueObservation?

        init(tab: BrowserTab, store: StoreOf<ResearchBrowserFeature>) {
            self.tabID = tab.id
            self.currentURL = tab.url
            self.store = store
        }

        deinit {
            progressObservation?.invalidate()
            titleObservation?.invalidate()
        }

        // MARK: - WKNavigationDelegate

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            store.send(.webViewStartedLoading(tabID: tabID))
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let canBack = webView.canGoBack
            let canForward = webView.canGoForward
            store.send(.webViewFinishedLoading(tabID: tabID, canGoBack: canBack, canGoForward: canForward))

            if let url = webView.url {
                currentURL = url
                store.send(.webViewNavigated(tabID: tabID, url: url, title: webView.title))
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            // Allow all navigation
            decisionHandler(.allow)

            // Track navigations triggered by links
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                currentURL = url
                store.send(.webViewNavigated(tabID: tabID, url: url, title: nil))
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            store.send(.webViewFinishedLoading(tabID: tabID, canGoBack: webView.canGoBack, canGoForward: webView.canGoForward))
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            store.send(.webViewFinishedLoading(tabID: tabID, canGoBack: webView.canGoBack, canGoForward: webView.canGoForward))
        }
    }
}
