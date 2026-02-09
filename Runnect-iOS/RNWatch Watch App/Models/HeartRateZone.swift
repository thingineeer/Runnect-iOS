//
//  HeartRateZone.swift
//  RNWatch Watch App
//
//  Created by Runnect on 2026/02/09.
//

import SwiftUI

enum HeartRateZone: Int, CaseIterable {
    case zone1 = 1  // 워밍업 50-60%
    case zone2 = 2  // 지방 연소 60-70%
    case zone3 = 3  // 유산소 70-80%
    case zone4 = 4  // 젖산 역치 80-90%
    case zone5 = 5  // 최대 90-100%

    var name: String {
        switch self {
        case .zone1: return "워밍업"
        case .zone2: return "지방 연소"
        case .zone3: return "유산소"
        case .zone4: return "젖산 역치"
        case .zone5: return "최대"
        }
    }

    var color: Color {
        switch self {
        case .zone1: return Color(red: 0x3B / 255, green: 0x82 / 255, blue: 0xF6 / 255)
        case .zone2: return Color(red: 0x22 / 255, green: 0xC5 / 255, blue: 0x5E / 255)
        case .zone3: return Color(red: 0xEA / 255, green: 0xB3 / 255, blue: 0x08 / 255)
        case .zone4: return Color(red: 0xF9 / 255, green: 0x73 / 255, blue: 0x16 / 255)
        case .zone5: return Color(red: 0xEF / 255, green: 0x44 / 255, blue: 0x44 / 255)
        }
    }

    var shortLabel: String {
        "Z\(rawValue)"
    }

    var range: ClosedRange<Double> {
        switch self {
        case .zone1: return 0.50...0.60
        case .zone2: return 0.60...0.70
        case .zone3: return 0.70...0.80
        case .zone4: return 0.80...0.90
        case .zone5: return 0.90...1.00
        }
    }

    static func zone(for heartRate: Double, maxHeartRate: Double = 190) -> HeartRateZone {
        guard maxHeartRate > 0 else { return .zone1 }
        let ratio = heartRate / maxHeartRate

        switch ratio {
        case ..<0.60: return .zone1
        case 0.60..<0.70: return .zone2
        case 0.70..<0.80: return .zone3
        case 0.80..<0.90: return .zone4
        default: return .zone5
        }
    }
}
