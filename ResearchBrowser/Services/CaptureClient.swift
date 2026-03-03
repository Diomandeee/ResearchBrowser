import Foundation
import Dependencies
import DependenciesMacros
import OpenClawSupabase

/// Client that saves captured nodes to the Supabase `graph_nodes` table.
@DependencyClient
struct CaptureClient: Sendable {
    var saveNode: @Sendable (CapturedNode) async throws -> Void
}

extension CaptureClient: DependencyKey {
    static let liveValue: CaptureClient = {
        CaptureClient(
            saveNode: { node in
                let row = GraphNodeRow(
                    id: node.id.uuidString,
                    kind: node.captureType.rawValue,
                    title: node.title,
                    url: node.url,
                    body: node.description,
                    selectedText: node.selectedText,
                    tags: node.tags,
                    capturedAt: ISO8601DateFormatter().string(from: node.capturedAt)
                )
                try await SupabaseManager.shared.client
                    .from("graph_nodes")
                    .insert(row)
                    .execute()
            }
        )
    }()

    static let testValue = CaptureClient()
}

extension DependencyValues {
    var captureClient: CaptureClient {
        get { self[CaptureClient.self] }
        set { self[CaptureClient.self] = newValue }
    }
}

// MARK: - Codable row for Supabase insert

private struct GraphNodeRow: Encodable {
    let id: String
    let kind: String
    let title: String
    let url: String
    let body: String
    let selectedText: String?
    let tags: [String]
    let capturedAt: String

    enum CodingKeys: String, CodingKey {
        case id, kind, title, url, body
        case selectedText = "selected_text"
        case tags
        case capturedAt = "captured_at"
    }
}
