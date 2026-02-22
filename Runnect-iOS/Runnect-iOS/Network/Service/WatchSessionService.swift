//
//  WatchSessionService.swift
//  Runnect-iOS
//
//  Created by Runnect on 2026/02/08.
//

import Foundation
import WatchConnectivity
import Combine

final class WatchSessionService: NSObject, ObservableObject {
    static let shared = WatchSessionService()

    @Published var isWatchReachable = false

    // MARK: - Health Data (received from Watch)

    @Published var realtimeHeartRate: Double = 0
    @Published var realtimeCalories: Double = 0
    @Published private(set) var healthSummary: WatchHealthSummary?

    private var sendTimer: AnyCancellable?

    private override init() {
        super.init()
    }

    func startSession() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - Send Running Data (5-second interval)

    func startSendingRunningData(provider: @escaping () -> [String: Any]?) {
        stopSendingRunningData()
        sendTimer = Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                guard
                      WCSession.default.isReachable,
                      let data = provider()
                else { return }
                WCSession.default.sendMessage(data, replyHandler: nil) { error in
                    print("[WatchSession] Send error: \(error.localizedDescription)")
                }
            }
    }

    func stopSendingRunningData() {
        sendTimer?.cancel()
        sendTimer = nil
    }

    // MARK: - One-shot Messages

    func sendCountdownStarted() {
        sendIfReachable(["messageType": "countdownStarted"])
    }

    func sendRunStarted() {
        sendIfReachable(["messageType": "runStarted"])
    }

    func sendRunCompleted() {
        sendIfReachable(["messageType": "runCompleted"])
    }

    func sendRunReset() {
        sendIfReachable(["messageType": "runReset"])
    }

    // MARK: - Health Data Management

    func clearHealthData() {
        realtimeHeartRate = 0
        realtimeCalories = 0
        healthSummary = nil
    }

    private func sendIfReachable(_ message: [String: Any], retryCount: Int = 0) {
        guard WCSession.default.activationState == .activated,
              WCSession.default.isReachable else {
            // Watch 미연결 시 transferUserInfo로 대기열에 추가 (중요 메시지만)
            if let type = message["messageType"] as? String,
               ["runCompleted", "runReset"].contains(type) {
                WCSession.default.transferUserInfo(message)
            }
            return
        }
        WCSession.default.sendMessage(message, replyHandler: nil) { [weak self] error in
            print("[WatchSession] Send error: \(error.localizedDescription)")
            // 중요 메시지 1회 재시도
            if retryCount < 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.sendIfReachable(message, retryCount: retryCount + 1)
                }
            }
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleIncomingMessage(message)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        handleIncomingMessage(message)
        replyHandler(["status": "received"])
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handleIncomingMessage(userInfo)
    }

    private func handleIncomingMessage(_ message: [String: Any]) {
        guard let type = message["messageType"] as? String else { return }

        switch type {
        case "command":
            if let command = message["command"] as? String {
                handleWatchCommand(command)
            }

        case "realtimeHealth":
            DispatchQueue.main.async {
                if let heartRate = message["heartRate"] as? Double {
                    self.realtimeHeartRate = heartRate
                }
                if let calories = message["calories"] as? Double {
                    self.realtimeCalories = calories
                }
                NotificationCenter.default.post(
                    name: .watchRealtimeHealthReceived,
                    object: nil,
                    userInfo: message
                )
            }

        case "healthSummary":
            if let summary = WatchHealthSummary.fromDictionary(message) {
                DispatchQueue.main.async {
                    self.healthSummary = summary
                    NotificationCenter.default.post(
                        name: .watchHealthSummaryReceived,
                        object: nil,
                        userInfo: message
                    )
                }
            }

        default:
            break
        }
    }

    private func handleWatchCommand(_ command: String) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .watchCommandReceived,
                object: nil,
                userInfo: ["command": command]
            )
        }
    }
}

// MARK: - WatchHealthSummary

struct WatchHealthSummary {
    let avgHeartRate: Double
    let maxHeartRate: Double
    let minHeartRate: Double?
    let totalCalories: Double
    let heartRateZones: [[String: Any]]
    let heartRateSamples: [[String: Any]]
    let timestamp: Date

    /// heartRateZones 배열에서 zone별 초(seconds) 추출
    var zoneDurations: [Int: Int] {
        var durations: [Int: Int] = [:]
        for zone in heartRateZones {
            if let zoneNum = zone["zone"] as? Int,
               let seconds = zone["durationSeconds"] as? Int {
                durations[zoneNum] = seconds
            }
        }
        return durations
    }

    static func fromDictionary(_ dict: [String: Any]) -> WatchHealthSummary? {
        guard let avgHeartRate = dict["avgHeartRate"] as? Double,
              let maxHeartRate = dict["maxHeartRate"] as? Double,
              let totalCalories = dict["totalCalories"] as? Double,
              let timestamp = dict["timestamp"] as? TimeInterval else {
            return nil
        }

        let zones = dict["heartRateZones"] as? [[String: Any]] ?? []
        let minHeartRate = dict["minHeartRate"] as? Double
        let samples = dict["heartRateSamples"] as? [[String: Any]] ?? []

        return WatchHealthSummary(
            avgHeartRate: avgHeartRate,
            maxHeartRate: maxHeartRate,
            minHeartRate: minHeartRate,
            totalCalories: totalCalories,
            heartRateZones: zones,
            heartRateSamples: samples,
            timestamp: Date(timeIntervalSince1970: timestamp)
        )
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "avgHeartRate": avgHeartRate,
            "maxHeartRate": maxHeartRate,
            "totalCalories": totalCalories,
            "heartRateZones": heartRateZones,
            "heartRateSamples": heartRateSamples,
            "timestamp": timestamp.timeIntervalSince1970
        ]
        if let minHeartRate {
            dict["minHeartRate"] = minHeartRate
        }
        return dict
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let watchCommandReceived = Notification.Name("watchCommandReceived")
    static let watchRealtimeHealthReceived = Notification.Name("watchRealtimeHealthReceived")
    static let watchHealthSummaryReceived = Notification.Name("watchHealthSummaryReceived")
}
