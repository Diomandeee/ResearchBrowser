import Foundation

/// The kind of knowledge capture.
enum CaptureType: String, CaseIterable, Identifiable, Codable {
    case reference
    case insight
    case quote
    case bookmark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .reference: return "Reference"
        case .insight:   return "Insight"
        case .quote:     return "Quote"
        case .bookmark:  return "Bookmark"
        }
    }

    var icon: String {
        switch self {
        case .reference: return "book.fill"
        case .insight:   return "lightbulb.fill"
        case .quote:     return "quote.bubble.fill"
        case .bookmark:  return "bookmark.fill"
        }
    }

    var description: String {
        switch self {
        case .reference: return "Save as research reference"
        case .insight:   return "An idea or realization"
        case .quote:     return "Notable quote or excerpt"
        case .bookmark:  return "Quick bookmark for later"
        }
    }
}

/// A node captured from the browser and destined for the knowledge graph.
struct CapturedNode: Equatable, Identifiable, Codable {
    let id: UUID
    var title: String
    var url: String
    var description: String
    var selectedText: String?
    var tags: [String]
    var captureType: CaptureType
    let capturedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "",
        url: String = "",
        description: String = "",
        selectedText: String? = nil,
        tags: [String] = [],
        captureType: CaptureType = .reference,
        capturedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.description = description
        self.selectedText = selectedText
        self.tags = tags
        self.captureType = captureType
        self.capturedAt = capturedAt
    }
}

/// Suggested tags displayed in the capture sheet.
let suggestedTags: [String] = [
    "research", "tutorial", "documentation", "article", "paper",
    "video", "tool", "library", "design", "architecture"
]
