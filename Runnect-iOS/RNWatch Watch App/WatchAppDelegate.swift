//
//  WatchAppDelegate.swift
//  RNWatch Watch App
//
//  Created by Runnect on 2026/02/08.
//

import WatchKit

final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        WatchSessionManager.shared.startSession()
    }
}
