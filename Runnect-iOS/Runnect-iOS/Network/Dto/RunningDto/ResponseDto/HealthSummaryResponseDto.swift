//
//  HealthSummaryResponseDto.swift
//  Runnect-iOS
//
//  Created by 이명진 on 2026/02/22.
//

import Foundation

// MARK: - HealthSummaryResponseDto

struct HealthSummaryResponseDto: Codable {
    let summary: HealthSummaryDetail
}

// MARK: - HealthSummaryDetail

struct HealthSummaryDetail: Codable {
    let totalRecords: Int
    let recordsWithHealth: Int
    let avgHeartRate: Double?
    let avgCalories: Double?
    let totalCalories: Double?
    let zoneDistribution: HealthZonesDto?
}
