import Foundation

/// Available search engines for the omnibox.
enum SearchEngine: String, CaseIterable, Identifiable, Codable {
    case google
    case duckDuckGo
    case perplexity
    case scholar
    case arxiv
    case github

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .google:       return "Google"
        case .duckDuckGo:   return "DuckDuckGo"
        case .perplexity:   return "Perplexity"
        case .scholar:      return "Google Scholar"
        case .arxiv:        return "arXiv"
        case .github:       return "GitHub"
        }
    }

    var icon: String {
        switch self {
        case .google:       return "magnifyingglass"
        case .duckDuckGo:   return "shield.fill"
        case .perplexity:   return "brain.head.profile"
        case .scholar:      return "graduationcap.fill"
        case .arxiv:        return "doc.text.fill"
        case .github:       return "chevron.left.forwardslash.chevron.right"
        }
    }

    /// Build a search URL by replacing `{query}` in the template.
    func searchURL(for query: String) -> URL? {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        let urlString = urlTemplate.replacingOccurrences(of: "{query}", with: encoded)
        return URL(string: urlString)
    }

    private var urlTemplate: String {
        switch self {
        case .google:       return "https://www.google.com/search?q={query}"
        case .duckDuckGo:   return "https://duckduckgo.com/?q={query}"
        case .perplexity:   return "https://www.perplexity.ai/search?q={query}"
        case .scholar:      return "https://scholar.google.com/scholar?q={query}"
        case .arxiv:        return "https://arxiv.org/search/?query={query}&searchtype=all"
        case .github:       return "https://github.com/search?q={query}"
        }
    }
}

// MARK: - Omnibox Input Parsing

enum OmniboxInput {
    /// Detect whether an input string is a URL or a search query, and return the
    /// resolved URL accordingly.
    static func resolve(_ input: String, engine: SearchEngine = .google) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if isURL(trimmed) {
            return normalize(trimmed)
        }
        return engine.searchURL(for: trimmed)
    }

    /// Returns `true` if the string looks like a URL.
    static func isURL(_ input: String) -> Bool {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Explicit scheme
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return true
        }

        // Domain pattern: something.tld
        let domainPattern = #"^[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+"#
        if trimmed.range(of: domainPattern, options: .regularExpression) != nil {
            return true
        }

        // localhost with optional port
        let localhostPattern = #"^localhost(:\d+)?"#
        if trimmed.range(of: localhostPattern, options: .regularExpression) != nil {
            return true
        }

        return false
    }

    /// Normalize a URL string by adding `https://` if no scheme is present.
    static func normalize(_ input: String) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return URL(string: trimmed)
        }
        return URL(string: "https://\(trimmed)")
    }
}
