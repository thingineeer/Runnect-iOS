//
//  RecordResponseDto.swift
//  Runnect-iOS
//
//  Created by Runnect on 2026/02/22.
//

import Foundation

// MARK: - RecordResponseDto

struct RecordResponseDto: Codable {
    let record: RecordDetail

    struct RecordDetail: Codable {
        let id: Int
        let createdAt: String
    }
}
