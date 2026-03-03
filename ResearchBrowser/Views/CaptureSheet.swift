import SwiftUI
import ComposableArchitecture

/// Bottom sheet for quickly capturing page content to the knowledge graph.
struct CaptureSheet: View {
    @Bindable var store: StoreOf<ResearchBrowserFeature>
    let sheetState: ResearchBrowserFeature.CaptureSheetState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Capture type selector
                    captureTypeGrid

                    // Title
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Title")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Enter a title...", text: titleBinding)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Description / notes
                    VStack(alignment: .leading, spacing: 4) {
                        Text(sheetState.node.captureType == .quote ? "Quote / Excerpt" : "Notes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: descriptionBinding)
                            .frame(minHeight: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color(.systemGray4), lineWidth: 0.5)
                            )
                    }

                    // Selected text preview
                    if let selectedText = sheetState.node.selectedText, !selectedText.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Selected Text")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(selectedText)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    // Tags
                    tagsSection

                    // URL preview
                    if !sheetState.node.url.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Source")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(sheetState.node.url)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.tertiary)
                                .lineLimit(2)
                        }
                    }

                    // Error
                    if let error = sheetState.errorMessage {
                        Label(error, systemImage: "exclamationmark.circle")
                            .font(.callout)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
            }
            .navigationTitle("Quick Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        store.send(.dismissCaptureSheet)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.captureSheetAction(.save))
                    } label: {
                        if sheetState.isSaving {
                            ProgressView()
                        } else {
                            Label("Save", systemImage: "checkmark")
                        }
                    }
                    .disabled(sheetState.isSaving)
                }
            }
        }
    }

    // MARK: - Capture Type Grid

    private var captureTypeGrid: some View {
        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: 8) {
            ForEach(CaptureType.allCases) { type in
                let isSelected = sheetState.node.captureType == type
                Button {
                    store.send(.captureSheetAction(.setCaptureType(type)))
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: type.icon)
                            .font(.system(size: 20))
                        Text(type.displayName)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        isSelected
                            ? Color.accentColor.opacity(0.15)
                            : Color(.systemGray6)
                    )
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                isSelected ? Color.accentColor : Color.clear,
                                lineWidth: 1.5
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Tags

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Current tags
            FlowLayout(spacing: 6) {
                ForEach(sheetState.node.tags, id: \.self) { tag in
                    HStack(spacing: 4) {
                        Text("#\(tag)")
                            .font(.system(size: 12))
                        Button {
                            store.send(.captureSheetAction(.removeTag(tag)))
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 8, weight: .bold))
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            // Tag input
            TextField("Add tags...", text: tagInputBinding)
                .font(.system(size: 13))
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    let input = sheetState.tagInput
                    if !input.isEmpty {
                        store.send(.captureSheetAction(.addTag(input)))
                    }
                }

            // Suggested tags
            FlowLayout(spacing: 4) {
                ForEach(
                    suggestedTags.filter { !sheetState.node.tags.contains($0) }.prefix(6),
                    id: \.self
                ) { tag in
                    Button {
                        store.send(.captureSheetAction(.addTag(tag)))
                    } label: {
                        Text("+\(tag)")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Bindings

    private var titleBinding: Binding<String> {
        Binding(
            get: { sheetState.node.title },
            set: { store.send(.captureSheetAction(.setTitle($0))) }
        )
    }

    private var descriptionBinding: Binding<String> {
        Binding(
            get: { sheetState.node.description },
            set: { store.send(.captureSheetAction(.setDescription($0))) }
        )
    }

    private var tagInputBinding: Binding<String> {
        Binding(
            get: { sheetState.tagInput },
            set: { store.send(.captureSheetAction(.setTagInput($0))) }
        )
    }
}

// MARK: - FlowLayout (simple wrapping HStack)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: ProposedViewSize(bounds.size), subviews: subviews)
        for (index, offset) in result.offsets.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, offsets: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var offsets: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            offsets.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalHeight = currentY + lineHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), offsets)
    }
}
