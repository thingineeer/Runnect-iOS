//
//  HealthDataResponseDto.swift
//  Runnect-iOS
//
//  Created by Runnect on 2026/02/22.
//

import Foundation

// MARK: - HealthDataResponseDto

struct HealthDataResponseDto: Codable {
    let healthData: HealthDataDetail?
}

// MARK: - HealthDataDetail

struct HealthDataDetail: Codable {
    let id: Int
    let recordId: Int
    let avgHeartRate: Double
    let maxHeartRate: Double
    let minHeartRate: Double?
    let calories: Double
    let zones: HealthZonesDto
    let maxHeartRateConfig: Double?
    let heartRateSamples: [HeartRateSampleDto]?
}

// MARK: - HealthZonesDto

struct HealthZonesDto: Codable {
    let zone1Seconds: Int
    let zone2Seconds: Int
    let zone3Seconds: Int
    let zone4Seconds: Int
    let zone5Seconds: Int
}
