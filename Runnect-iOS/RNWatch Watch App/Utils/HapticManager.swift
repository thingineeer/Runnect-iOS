//
//  HapticManager.swift
//  RNWatch Watch App
//
//  Created by Runnect on 2026/02/08.
//

import WatchKit

enum HapticManager {
    static func kilometerReached() {
        WKInterfaceDevice.current().play(.click)
    }

    static func paceAboveZone() {
        WKInterfaceDevice.current().play(.directionUp)
    }

    static func paceBelowZone() {
        WKInterfaceDevice.current().play(.directionDown)
    }

    static func runCompleted() {
        WKInterfaceDevice.current().play(.success)
    }

    static func heartRateZoneAlert() {
        WKInterfaceDevice.current().play(.notification)
    }
}
