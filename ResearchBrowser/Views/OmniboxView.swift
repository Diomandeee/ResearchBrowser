import SwiftUI
import ComposableArchitecture

/// Combined URL/search text field with search engine selector.
struct OmniboxView: View {
    @Binding var text: String
    @Binding var isFocused: Bool
    @Binding var selectedEngine: SearchEngine
    let isLoading: Bool
    let currentURL: String
    let onSubmit: () -> Void

    @FocusState private var fieldFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            // Search engine picker (visible when focused)
            if isFocused {
                Menu {
                    ForEach(SearchEngine.allCases) { engine in
                        Button {
                            selectedEngine = engine
                        } label: {
                            Label(engine.displayName, systemImage: engine.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 2) {
                        Text(selectedEngine.displayName)
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            // Input field
            HStack(spacing: 6) {
                // Lock / loading indicator
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 14, height: 14)
                } else if !isFocused && currentURL.hasPrefix("https://") {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.green)
                }

                TextField("Search or enter URL...", text: $text)
                    .font(.system(size: 14))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.webSearch)
                    .submitLabel(.go)
                    .focused($fieldFocused)
                    .onSubmit { onSubmit() }

                // Clear button
                if isFocused && !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        isFocused ? Color.accentColor : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .onChange(of: fieldFocused) { _, focused in
            isFocused = focused
            if focused {
                // Select all text when focused
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    // UITextField select-all isn't directly available via SwiftUI,
                    // but the binding update triggers a display refresh
                }
            } else {
                // Reset to current URL on blur
                text = currentURL
            }
        }
        .onChange(of: isFocused) { _, focused in
            fieldFocused = focused
        }
    }
}
