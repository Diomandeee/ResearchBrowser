import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "star.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Research Browser")
                    .font(.largeTitle.bold())

                Text("Welcome to Research Browser")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Research Browser")
        }
    }
}

#Preview {
    ContentView()
}
