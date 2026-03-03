import Foundation

/// A single browser tab within the Research Browser.
struct BrowserTab: Equatable, Identifiable, Codable {
    let id: UUID
    var url: URL
    var title: String
    var favicon: URL?
    var isLoading: Bool
    var canGoBack: Bool
    var canGoForward: Bool
    var estimatedProgress: Double
    let createdAt: Date

    init(
        id: UUID = UUID(),
        url: URL = URL(string: "https://www.google.com")!,
        title: String = "New Tab",
        favicon: URL? = nil,
        isLoading: Bool = false,
        canGoBack: Bool = false,
        canGoForward: Bool = false,
        estimatedProgress: Double = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.favicon = favicon
        self.isLoading = isLoading
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
        self.estimatedProgress = estimatedProgress
        self.createdAt = createdAt
    }
}

extension BrowserTab {
    /// The domain portion of the URL, stripped of "www." prefix.
    var domain: String {
        let host = url.host ?? url.absoluteString
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    /// Display-friendly URL: hostname + path + query, without the scheme.
    var displayURL: String {
        guard let host = url.host else { return url.absoluteString }
        let cleanHost = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        let path = url.path == "/" ? "" : url.path
        let query = url.query.map { "?\($0)" } ?? ""
        return cleanHost + path + query
    }
}
