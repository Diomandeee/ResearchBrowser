import SwiftUI
import ComposableArchitecture

/// Horizontal scrollable tab bar above the web content area.
struct TabBarView: View {
    let tabs: IdentifiedArrayOf<BrowserTab>
    let activeTabID: UUID?
    let onSelect: (UUID) -> Void
    let onClose: (UUID) -> Void
    let onNewTab: () -> Void

    var body: some View {
        if tabs.isEmpty { return AnyView(EmptyView()) }

        return AnyView(
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(tabs) { tab in
                        tabItem(tab)
                    }

                    // New tab button
                    Button(action: onNewTab) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 28)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .frame(height: 36)
            .background(Color(.systemGray6).opacity(0.5))
        )
    }

    @ViewBuilder
    private func tabItem(_ tab: BrowserTab) -> some View {
        let isActive = tab.id == activeTabID
        Button {
            onSelect(tab.id)
        } label: {
            HStack(spacing: 6) {
                // Loading indicator or globe
                if tab.isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 14, height: 14)
                } else {
                    Image(systemName: "globe")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }

                // Title
                Text(tab.title.isEmpty ? tab.domain : tab.title)
                    .font(.system(size: 11))
                    .lineLimit(1)
                    .foregroundStyle(isActive ? .primary : .secondary)

                // Close button
                Button {
                    onClose(tab.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 16, height: 16)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                isActive
                    ? Color(.systemBackground)
                    : Color(.systemGray6)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isActive ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: 180)
    }
}
