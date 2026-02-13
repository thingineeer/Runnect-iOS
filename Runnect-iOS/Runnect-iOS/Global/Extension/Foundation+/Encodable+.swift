//
//  Encodable+.swift
//  Runnect-iOS
//
//  Created by sejin on 2022/12/31.
//

import Foundation

// MARK: - Encodable Extension

extension Encodable {
    func asParameter() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                as? [String: Any] else {
            throw NSError(domain: "EncodableExtension", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert to dictionary"])
        }
        return dictionary
    }
}
