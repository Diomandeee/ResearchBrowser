import ComposableArchitecture
import Foundation

@Reducer
struct ResearchBrowserFeature {
    // MARK: - Constants

    static let maxTabs = 10
    static let defaultURL = URL(string: "https://www.google.com")!

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var tabs: IdentifiedArrayOf<BrowserTab> = []
        var activeTabID: UUID? = nil
        var selectedSearchEngine: SearchEngine = .google
        var omniboxText: String = ""
        var isOmniboxFocused: Bool = false

        // Find in page
        var findQuery: String = ""
        var isFindVisible: Bool = false

        // Capture
        var captureSheet: CaptureSheetState? = nil

        // Derived
        var activeTab: BrowserTab? {
            guard let id = activeTabID else { return nil }
            return tabs[id: id]
        }

        var canGoBack: Bool { activeTab?.canGoBack ?? false }
        var canGoForward: Bool { activeTab?.canGoForward ?? false }
        var isLoading: Bool { activeTab?.isLoading ?? false }
    }

    // MARK: - Capture Sheet State

    @ObservableState
    struct CaptureSheetState: Equatable, Identifiable {
        let id = UUID()
        var node: CapturedNode
        var tagInput: String = ""
        var isSaving: Bool = false
        var errorMessage: String? = nil
    }

    // MARK: - Action

    enum Action: BindableAction {
        case binding(BindingAction<State>)

        // Tab management
        case createTab(URL?)
        case closeTab(UUID)
        case selectTab(UUID)

        // Navigation
        case omniboxSubmitted
        case goBack
        case goForward
        case reload

        // WebView delegate callbacks
        case webViewNavigated(tabID: UUID, url: URL, title: String?)
        case webViewProgressChanged(tabID: UUID, progress: Double)
        case webViewFinishedLoading(tabID: UUID, canGoBack: Bool, canGoForward: Bool)
        case webViewStartedLoading(tabID: UUID)
        case webViewTitleChanged(tabID: UUID, title: String)

        // Find in page
        case toggleFind
        case findInPage(String)
        case dismissFind

        // Quick capture
        case openCaptureSheet
        case captureSheetAction(CaptureSheetAction)
        case dismissCaptureSheet

        // JS injection for selected text
        case selectedTextReceived(String?)
    }

    enum CaptureSheetAction {
        case save
        case saveCompleted(Result<Void, Error>)
        case addTag(String)
        case removeTag(String)
        case setCaptureType(CaptureType)
        case setTitle(String)
        case setDescription(String)
        case setTagInput(String)
    }

    // MARK: - Dependencies

    @Dependency(\.captureClient) var captureClient
    @Dependency(\.uuid) var uuid

    // MARK: - Reducer

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            // ── Tab Management ──────────────────────────────────────────

            case let .createTab(url):
                guard state.tabs.count < Self.maxTabs else { return .none }
                let tab = BrowserTab(id: uuid(), url: url ?? Self.defaultURL)
                state.tabs.append(tab)
                state.activeTabID = tab.id
                state.omniboxText = tab.url.absoluteString
                return .none

            case let .closeTab(id):
                guard let index = state.tabs.index(id: id) else { return .none }
                state.tabs.remove(id: id)

                if state.activeTabID == id {
                    if state.tabs.isEmpty {
                        state.activeTabID = nil
                        state.omniboxText = ""
                    } else {
                        let newIndex = min(index, state.tabs.count - 1)
                        let newTab = state.tabs[newIndex]
                        state.activeTabID = newTab.id
                        state.omniboxText = newTab.url.absoluteString
                    }
                }
                return .none

            case let .selectTab(id):
                guard state.tabs[id: id] != nil else { return .none }
                state.activeTabID = id
                if let tab = state.tabs[id: id] {
                    state.omniboxText = tab.url.absoluteString
                }
                return .none

            // ── Navigation ──────────────────────────────────────────────

            case .omniboxSubmitted:
                let text = state.omniboxText
                guard let resolved = OmniboxInput.resolve(text, engine: state.selectedSearchEngine) else {
                    return .none
                }

                if let tabID = state.activeTabID {
                    state.tabs[id: tabID]?.url = resolved
                    state.tabs[id: tabID]?.isLoading = true
                } else {
                    // No tabs open -- create one
                    return .send(.createTab(resolved))
                }
                state.isOmniboxFocused = false
                return .none

            case .goBack:
                return .none // Handled by WebContentView coordinator

            case .goForward:
                return .none // Handled by WebContentView coordinator

            case .reload:
                if let id = state.activeTabID {
                    state.tabs[id: id]?.isLoading = true
                }
                return .none // Handled by WebContentView coordinator

            // ── WebView Delegate Callbacks ───────────────────────────────

            case let .webViewNavigated(tabID, url, title):
                state.tabs[id: tabID]?.url = url
                if let title = title, !title.isEmpty {
                    state.tabs[id: tabID]?.title = title
                }
                if tabID == state.activeTabID {
                    state.omniboxText = url.absoluteString
                }
                return .none

            case let .webViewProgressChanged(tabID, progress):
                state.tabs[id: tabID]?.estimatedProgress = progress
                return .none

            case let .webViewFinishedLoading(tabID, canGoBack, canGoForward):
                state.tabs[id: tabID]?.isLoading = false
                state.tabs[id: tabID]?.estimatedProgress = 1.0
                state.tabs[id: tabID]?.canGoBack = canGoBack
                state.tabs[id: tabID]?.canGoForward = canGoForward
                return .none

            case let .webViewStartedLoading(tabID):
                state.tabs[id: tabID]?.isLoading = true
                state.tabs[id: tabID]?.estimatedProgress = 0
                return .none

            case let .webViewTitleChanged(tabID, title):
                state.tabs[id: tabID]?.title = title
                return .none

            // ── Find In Page ────────────────────────────────────────────

            case .toggleFind:
                state.isFindVisible.toggle()
                if !state.isFindVisible {
                    state.findQuery = ""
                }
                return .none

            case let .findInPage(query):
                state.findQuery = query
                return .none // JS evaluation delegated to WebContentView

            case .dismissFind:
                state.isFindVisible = false
                state.findQuery = ""
                return .none

            // ── Quick Capture ───────────────────────────────────────────

            case .openCaptureSheet:
                guard let tab = state.activeTab else { return .none }
                let node = CapturedNode(
                    title: tab.title,
                    url: tab.url.absoluteString,
                    captureType: .reference
                )
                state.captureSheet = CaptureSheetState(node: node)
                return .none

            case let .selectedTextReceived(text):
                if let text = text, !text.isEmpty, state.captureSheet != nil {
                    state.captureSheet?.node.selectedText = text
                    state.captureSheet?.node.description = text
                    state.captureSheet?.node.captureType = .quote
                }
                return .none

            case .captureSheetAction(.save):
                guard var sheet = state.captureSheet else { return .none }
                guard !sheet.node.title.trimmingCharacters(in: .whitespaces).isEmpty else {
                    sheet.errorMessage = "Title is required"
                    state.captureSheet = sheet
                    return .none
                }
                sheet.isSaving = true
                sheet.errorMessage = nil
                state.captureSheet = sheet
                let node = sheet.node
                return .run { send in
                    do {
                        try await captureClient.saveNode(node)
                        await send(.captureSheetAction(.saveCompleted(.success(()))))
                    } catch {
                        await send(.captureSheetAction(.saveCompleted(.failure(error))))
                    }
                }

            case .captureSheetAction(.saveCompleted(.success)):
                state.captureSheet = nil
                return .none

            case let .captureSheetAction(.saveCompleted(.failure(error))):
                state.captureSheet?.isSaving = false
                state.captureSheet?.errorMessage = error.localizedDescription
                return .none

            case let .captureSheetAction(.addTag(tag)):
                let normalized = tag.lowercased().trimmingCharacters(in: .whitespaces)
                guard !normalized.isEmpty else { return .none }
                if state.captureSheet?.node.tags.contains(normalized) == false {
                    state.captureSheet?.node.tags.append(normalized)
                }
                state.captureSheet?.tagInput = ""
                return .none

            case let .captureSheetAction(.removeTag(tag)):
                state.captureSheet?.node.tags.removeAll { $0 == tag }
                return .none

            case let .captureSheetAction(.setCaptureType(type)):
                state.captureSheet?.node.captureType = type
                return .none

            case let .captureSheetAction(.setTitle(title)):
                state.captureSheet?.node.title = title
                return .none

            case let .captureSheetAction(.setDescription(desc)):
                state.captureSheet?.node.description = desc
                return .none

            case let .captureSheetAction(.setTagInput(input)):
                state.captureSheet?.tagInput = input
                return .none

            case .dismissCaptureSheet:
                state.captureSheet = nil
                return .none
            }
        }
    }
}
