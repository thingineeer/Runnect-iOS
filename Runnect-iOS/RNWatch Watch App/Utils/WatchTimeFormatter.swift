//
//  WatchTimeFormatter.swift
//  RNWatch Watch App
//
//  Created by 이명진 on 2026/02/08.
//

import Foundation

enum WatchTimeFormatter {
    static func secondsToHHMMSS(seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    static func paceString(secondsPerKm: Int) -> String {
        let m = secondsPerKm / 60
        let s = secondsPerKm % 60
        return String(format: "%d'%02d''", m, s)
    }
}
