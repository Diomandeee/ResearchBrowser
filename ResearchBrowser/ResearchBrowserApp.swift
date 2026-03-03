import SwiftUI
import ComposableArchitecture
import OpenClawCore

@main
struct ResearchBrowserApp: App {
    init() {
        KeychainHelper.service = "com.openclaw.researchbrowser"
    }

    var body: some Scene {
        WindowGroup {
            ResearchBrowserView(
                store: Store(initialState: ResearchBrowserFeature.State()) {
                    ResearchBrowserFeature()
                }
            )
        }
    }
}
