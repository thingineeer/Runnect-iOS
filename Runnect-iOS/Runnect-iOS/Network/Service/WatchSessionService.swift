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

    private func sendIfReachable(_ message: [String: Any]) {
        guard WCSession.default.activationState == .activated,
              WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("[WatchSession] Send error: \(error.localizedDescription)")
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
        guard let type = message["messageType"] as? String else { return }

        switch type {
        case "command":
            if let command = message["command"] as? String {
                handleWatchCommand(command)
            }
        default:
            break
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        self.session(session, didReceiveMessage: message)
        replyHandler(["status": "received"])
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

// MARK: - Notification Names

extension Notification.Name {
    static let watchCommandReceived = Notification.Name("watchCommandReceived")
}
