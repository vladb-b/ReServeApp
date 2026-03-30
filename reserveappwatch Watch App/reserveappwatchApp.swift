//
//  reserveappwatchApp.swift
//  reserveappwatch Watch App
//
//  Created by VI on 22/03/2026.
//

import SwiftUI

@main
struct reserveappwatch_Watch_AppApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var bookingManager = BookingManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bookingManager)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                bookingManager.refreshSync()
            }
        }
    }
}
