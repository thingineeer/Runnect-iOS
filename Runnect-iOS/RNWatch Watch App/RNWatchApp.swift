//
//  RNWatchApp.swift
//  RNWatch Watch App
//
//  Created by 이명진 on 2/8/26.
//

import SwiftUI

@main
struct RNWatchApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                RunningIdleView()
            }
            .environmentObject(WatchSessionManager.shared)
            .environmentObject(WorkoutManager.shared)
        }
    }
}
