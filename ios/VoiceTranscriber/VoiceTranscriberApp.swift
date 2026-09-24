import SwiftUI

@main
struct VoiceTranscriberApp: App {
    @StateObject private var viewModel = TranscriberViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}
