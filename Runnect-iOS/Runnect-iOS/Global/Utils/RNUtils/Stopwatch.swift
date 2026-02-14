//
//  Stopwatch.swift
//  Runnect-iOS
//
//  Created by sejin on 2023/01/04.
//

import Combine
import Foundation

class Stopwatch {
    private var startTime: Date?
    private var accumulatedTime: TimeInterval = 0
    private var timer: Cancellable?
    
    @Published var isRunning = false {
        didSet {
            if self.isRunning {
                self.start()
            } else {
                self.stop()
            }
        }
    }
    
    @Published private(set) var elapsedTime: TimeInterval = 0
    
    private func start() {
        self.startTime = Date()
        self.timer?.cancel()
        self.timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.elapsedTime = self.getElapsedTime()
            }
    }
    
    private func stop() {
        self.timer?.cancel()
        self.timer = nil
        self.accumulatedTime = self.getElapsedTime()
        self.startTime = nil
    }
    
    func reset() {
        self.accumulatedTime = 0
        self.elapsedTime = 0
        self.startTime = nil
        self.isRunning = false
    }
    
    private func getElapsedTime() -> TimeInterval {
        guard let start = self.startTime else { return self.accumulatedTime }
        return max(0, Date().timeIntervalSince(start) + self.accumulatedTime)
    }
}
