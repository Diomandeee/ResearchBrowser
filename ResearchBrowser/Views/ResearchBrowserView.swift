import SwiftUI
import ComposableArchitecture

/// Main browser view with tab bar, omnibox, web content, and quick capture.
struct ResearchBrowserView: View {
    @Bindable var store: StoreOf<ResearchBrowserFeature>

    // Navigation action signals (toggled to trigger UIView updates)
    @State private var goBackSignal = false
    @State private var goForwardSignal = false
    @State private var reloadSignal = false

    var body: some View {
        VStack(spacing: 0) {
            // Top toolbar: navigation buttons + omnibox
            toolbar

            // Progress bar
            if store.isLoading, let tab = store.activeTab {
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: geo.size.width * tab.estimatedProgress, height: 2)
                        .animation(.linear(duration: 0.2), value: tab.estimatedProgress)
                }
                .frame(height: 2)
            }

            // Tab bar
            TabBarView(
                tabs: store.tabs,
                activeTabID: store.activeTabID,
                onSelect: { store.send(.selectTab($0)) },
                onClose: { store.send(.closeTab($0)) },
                onNewTab: { store.send(.createTab(nil)) }
            )

            // Web content
            ZStack {
                if store.tabs.isEmpty {
                    emptyState
                } else if let tab = store.activeTab {
                    WebContentView(
                        tab: tab,
                        findQuery: store.findQuery,
                        store: store,
                        goBackSignal: goBackSignal,
                        goForwardSignal: goForwardSignal,
                        reloadSignal: reloadSignal
                    )
                    .id(tab.id) // Force recreation when switching tabs
                }

                // Find bar overlay
                if store.isFindVisible {
                    findBar
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(item: $store.captureSheet) { sheet in
            CaptureSheet(store: store, sheetState: sheet)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 8) {
            // Navigation buttons
            HStack(spacing: 4) {
                Button {
                    goBackSignal.toggle()
                    store.send(.goBack)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                }
                .disabled(!store.canGoBack)

                Button {
                    goForwardSignal.toggle()
                    store.send(.goForward)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                }
                .disabled(!store.canGoForward)

                Button {
                    reloadSignal.toggle()
                    store.send(.reload)
                } label: {
                    Image(systemName: store.isLoading ? "xmark" : "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            // Omnibox
            OmniboxView(
                text: $store.omniboxText,
                isFocused: $store.isOmniboxFocused,
                selectedEngine: $store.selectedSearchEngine,
                isLoading: store.isLoading,
                currentURL: store.activeTab?.url.absoluteString ?? "",
                onSubmit: { store.send(.omniboxSubmitted) }
            )

            // Action buttons
            HStack(spacing: 4) {
                // Find in page
                Button {
                    store.send(.toggleFind)
                } label: {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 14))
                }

                // Quick capture
                Button {
                    store.send(.openCaptureSheet)
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 14))
                }
                .disabled(store.activeTab == nil)

                // New tab
                Button {
                    store.send(.createTab(nil))
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - Find Bar

    private var findBar: some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Find in page...", text: $store.findQuery)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 14))
                    .onSubmit {
                        store.send(.findInPage(store.findQuery))
                    }

                Button {
                    store.send(.dismissFind)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer().frame(height: 40)

                // Hero
                VStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)

                    Text("Research Browser")
                        .font(.title2.bold())

                    Text("Browse the web and capture knowledge to your graph.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                // Quick links
                VStack(alignment: .leading, spacing: 16) {
                    quickLinkSection(title: "SEARCH", links: [
                        ("Google", "https://google.com", "magnifyingglass"),
                        ("Google Scholar", "https://scholar.google.com", "graduationcap.fill"),
                        ("Perplexity", "https://perplexity.ai", "brain.head.profile"),
                    ])

                    quickLinkSection(title: "CODE & DOCS", links: [
                        ("GitHub", "https://github.com", "chevron.left.forwardslash.chevron.right"),
                        ("Stack Overflow", "https://stackoverflow.com", "text.book.closed.fill"),
                        ("MDN Web Docs", "https://developer.mozilla.org", "globe"),
                    ])

                    quickLinkSection(title: "RESEARCH", links: [
                        ("arXiv", "https://arxiv.org", "doc.text.fill"),
                        ("Papers With Code", "https://paperswithcode.com", "chart.bar.fill"),
                        ("Hacker News", "https://news.ycombinator.com", "newspaper.fill"),
                    ])
                }
                .padding(.horizontal, 20)

                // New tab button
                Button {
                    store.send(.createTab(nil))
                } label: {
                    Label("New Tab", systemImage: "plus")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Spacer().frame(height: 40)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private func quickLinkSection(title: String, links: [(String, String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tertiary)
                .tracking(1)

            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 8) {
                ForEach(links, id: \.0) { name, urlString, icon in
                    Button {
                        if let url = URL(string: urlString) {
                            store.send(.createTab(url))
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: icon)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                            Text(name)
                                .font(.system(size: 13))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
