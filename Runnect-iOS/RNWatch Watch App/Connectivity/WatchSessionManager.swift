//
//  WatchSessionManager.swift
//  RNWatch Watch App
//
//  Created by Runnect on 2026/02/08.
//

import Foundation
import WatchConnectivity
import Combine

final class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()

    @Published var isReachable = false
    @Published var runningData = WatchRunningData.empty
    @Published var runningState: RunningState = .idle

    private var lastKilometer = 0
    private var cancellables = Set<AnyCancellable>()

    // Fallback local stopwatch when iPhone is unreachable
    @Published var localElapsedTime: Int = 0
    private var localTimer: AnyCancellable?
    private var localTimerStartDate: Date?
    private var localAccumulatedTime: TimeInterval = 0

    enum RunningState {
        case idle
        case countdown
        case active
        case paused
        case summary
    }

    private override init() {
        super.init()
    }

    func startSession() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - Kilometer Tracking

    private func checkKilometerMilestone() {
        let currentKm = runningData.completedKilometers
        if currentKm > lastKilometer && currentKm > 0 {
            lastKilometer = currentKm
            HapticManager.kilometerReached()
            NotificationCenter.default.post(
                name: .kilometerReached,
                object: nil,
                userInfo: ["km": currentKm, "pace": runningData.pace]
            )
        }
    }

    // MARK: - Pace Zone Haptics

    private func checkPaceZone(targetPace: Int) {
        guard runningData.pace > 0, targetPace > 0 else { return }
        let threshold = 15 // 15 seconds tolerance
        if runningData.pace > targetPace + threshold {
            HapticManager.paceBelowZone()
        } else if runningData.pace < targetPace - threshold {
            HapticManager.paceAboveZone()
        }
    }

    // MARK: - Local Fallback Timer

    func startLocalTimer() {
        localTimerStartDate = Date()
        localAccumulatedTime = TimeInterval(localElapsedTime)
        localTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let start = self.localTimerStartDate else { return }
                self.localElapsedTime = Int(-start.timeIntervalSinceNow + self.localAccumulatedTime)
            }
    }

    func stopLocalTimer() {
        localTimer?.cancel()
        localTimer = nil
        if let start = localTimerStartDate {
            localAccumulatedTime = -start.timeIntervalSinceNow + localAccumulatedTime
        }
        localTimerStartDate = nil
    }

    func resetLocalTimer() {
        stopLocalTimer()
        localElapsedTime = 0
        localAccumulatedTime = 0
    }

    func resetRunning() {
        lastKilometer = 0
        runningData = .empty
        resetLocalTimer()
        runningState = .idle
    }

    // MARK: - Send control messages to iPhone

    func sendRunCommand(_ command: String) {
        let payload: [String: Any] = ["messageType": "command", "command": command]

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil) { [weak self] _ in
                // sendMessage failed, fallback to guaranteed delivery
                self?.sendViaTransfer(payload)
            }
        } else {
            // iPhone unreachable, use transferUserInfo for guaranteed delivery
            sendViaTransfer(payload)
        }
    }

    private func sendViaTransfer(_ payload: [String: Any]) {
        guard WCSession.default.activationState == .activated else { return }
        WCSession.default.transferUserInfo(payload)
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            self.handleMessage(message)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        DispatchQueue.main.async {
            self.handleMessage(message)
            replyHandler(["status": "received"])
        }
    }

    private func handleMessage(_ message: [String: Any]) {
        guard let type = message[WatchRunningData.Keys.messageType] as? String else { return }

        switch type {
        case "runningUpdate":
            if let data = WatchRunningData(from: message) {
                let wasRunning = runningData.isRunning
                runningData = data

                if data.isRunning && !wasRunning {
                    runningState = .active
                    startLocalTimer()
                } else if !data.isRunning && wasRunning {
                    stopLocalTimer()
                }

                // Sync local timer with iPhone data
                localElapsedTime = data.elapsedTime

                checkKilometerMilestone()

                // Check pace zone if target pace is provided
                if let targetPace = message["targetPace"] as? Int, targetPace > 0 {
                    checkPaceZone(targetPace: targetPace)
                }
            }

        case "runStarted":
            runningState = .countdown
            lastKilometer = 0
            resetLocalTimer()

        case "runCompleted":
            runningState = .summary
            stopLocalTimer()
            HapticManager.runCompleted()

        case "runReset":
            resetRunning()

        default:
            break
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let kilometerReached = Notification.Name("kilometerReached")
}
