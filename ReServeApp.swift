import SwiftUI

@main
struct ReServeApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var bookingManager = BookingManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bookingManager)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                bookingManager.refreshSync()
            }
        }
    }
}
