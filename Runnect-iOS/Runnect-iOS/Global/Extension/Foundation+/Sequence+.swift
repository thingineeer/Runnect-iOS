//
//  Sequence+.swift
//  Runnect-iOS
//
//  Created by 이명진 on 2026/02/19.
//

import Foundation

extension Sequence {
    /// 주어진 keyPath 기준으로 중복을 제거하여 순서를 유지한 배열을 반환합니다.
    func uniqued<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}
