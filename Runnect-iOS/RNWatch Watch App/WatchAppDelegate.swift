//
//  WatchAppDelegate.swift
//  RNWatch Watch App
//
//  Created by 이명진 on 2026/02/08.
//

import WatchKit

final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        WatchSessionManager.shared.startSession()
    }
}
