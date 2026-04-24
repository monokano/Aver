import SwiftUI

@main
struct AverApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 300, height: 550)
        .commands {
            AverCommands()
        }
    }
}
