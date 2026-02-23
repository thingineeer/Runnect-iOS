//
//  HealthDataSaveRequestDto.swift
//  Runnect-iOS
//
//  Created by Runnect on 2026/02/22.
//

import Foundation

// MARK: - HealthDataSaveRequestDto

struct HealthDataSaveRequestDto: Codable {
    let avgHeartRate: Double
    let maxHeartRate: Double
    let minHeartRate: Double?
    let calories: Double
    let zone1Seconds: Int
    let zone2Seconds: Int
    let zone3Seconds: Int
    let zone4Seconds: Int
    let zone5Seconds: Int
    let maxHeartRateConfig: Double?
    let heartRateSamples: [HeartRateSampleDto]?
}

// MARK: - HeartRateSampleDto

struct HeartRateSampleDto: Codable {
    let heartRate: Double
    let elapsedSeconds: Int
    let zone: Int
}
