//
//  WorkoutManager.swift
//  RNWatch Watch App
//
//  Created by Runnect on 2026/02/08.
//

import Foundation
import HealthKit
import Combine

final class WorkoutManager: NSObject, ObservableObject {
    static let shared = WorkoutManager()

    @Published var heartRate: Double = 0
    @Published var activeCalories: Double = 0
    @Published var isWorkoutActive = false
    @Published var currentZone: HeartRateZone = .zone1

    // Summary values preserved after workout ends
    @Published var summaryHeartRate: Double = 0
    @Published var summaryCalories: Double = 0
    @Published var summaryMaxHeartRate: Double = 0

    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?

    // Heart rate sample tracking for zone distribution
    private var heartRateSamples: [(bpm: Double, date: Date)] = []
    private var maxHeartRateValue: Double = 0
    private let estimatedMaxHR: Double = 190

    private override init() {
        super.init()
    }

    // MARK: - Authorization

    func requestAuthorization() {
        let typesToShare: Set<HKSampleType> = [
            HKQuantityType.workoutType()
        ]
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType(.heartRate),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning)
        ]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if let error {
                print("[WorkoutManager] Auth error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Start Workout

    func startWorkout() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor

        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()

            workoutSession?.delegate = self
            workoutBuilder?.delegate = self

            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )

            heartRateSamples.removeAll()
            maxHeartRateValue = 0

            let startDate = Date()
            workoutSession?.startActivity(with: startDate)
            workoutBuilder?.beginCollection(withStart: startDate) { success, error in
                if let error {
                    print("[WorkoutManager] Begin collection error: \(error.localizedDescription)")
                }
            }

            DispatchQueue.main.async {
                self.isWorkoutActive = true
            }
        } catch {
            print("[WorkoutManager] Start workout error: \(error.localizedDescription)")
        }
    }

    // MARK: - End Workout

    func endWorkout() {
        // Preserve summary values before session ends and triggers reset
        summaryHeartRate = heartRate
        summaryCalories = activeCalories
        summaryMaxHeartRate = maxHeartRateValue

        // Use averageQuantity for heart rate if available
        if let builder = workoutBuilder,
           let hrStats = builder.statistics(for: HKQuantityType(.heartRate)) {
            let hrUnit = HKUnit.count().unitDivided(by: .minute())
            if let avg = hrStats.averageQuantity()?.doubleValue(for: hrUnit) {
                summaryHeartRate = avg
            }
            if let max = hrStats.maximumQuantity()?.doubleValue(for: hrUnit) {
                summaryMaxHeartRate = max
            }
        }

        // Send health summary to iPhone via transferUserInfo
        sendHealthSummaryToiPhone()

        workoutSession?.end()

        DispatchQueue.main.async {
            self.isWorkoutActive = false
        }
    }

    // MARK: - Health Summary

    func generateHealthSummary() -> [String: Any] {
        let avgHR = summaryHeartRate
        let maxHR = summaryMaxHeartRate
        let calories = summaryCalories
        let zones = calculateZoneDistribution()

        var zoneList: [[String: Any]] = []
        for zone in zones {
            zoneList.append([
                "zone": zone.zone.rawValue,
                "zoneName": zone.zone.name,
                "durationSeconds": zone.durationSeconds,
                "percentage": zone.percentage
            ])
        }

        return [
            "messageType": "healthSummary",
            "avgHeartRate": round(avgHR * 10) / 10,
            "maxHeartRate": round(maxHR * 10) / 10,
            "totalCalories": round(calories * 10) / 10,
            "heartRateZones": zoneList,
            "timestamp": Date().timeIntervalSince1970
        ]
    }

    private func sendHealthSummaryToiPhone() {
        let summary = generateHealthSummary()
        WatchSessionManager.shared.sendHealthSummary(summary)
    }

    private func calculateZoneDistribution() -> [(zone: HeartRateZone, durationSeconds: Int, percentage: Double)] {
        guard heartRateSamples.count >= 2 else { return [] }

        var zoneDurations: [HeartRateZone: TimeInterval] = [:]
        for zone in HeartRateZone.allCases {
            zoneDurations[zone] = 0
        }

        for i in 0..<(heartRateSamples.count - 1) {
            let sample = heartRateSamples[i]
            let nextSample = heartRateSamples[i + 1]
            let duration = nextSample.date.timeIntervalSince(sample.date)
            let zone = HeartRateZone.zone(for: sample.bpm, maxHeartRate: estimatedMaxHR)
            zoneDurations[zone, default: 0] += duration
        }

        if let lastSample = heartRateSamples.last {
            let zone = HeartRateZone.zone(for: lastSample.bpm, maxHeartRate: estimatedMaxHR)
            zoneDurations[zone, default: 0] += 5
        }

        let totalDuration = zoneDurations.values.reduce(0, +)
        guard totalDuration > 0 else { return [] }

        return HeartRateZone.allCases.compactMap { zone in
            let duration = zoneDurations[zone] ?? 0
            guard duration > 0 else { return nil }
            return (
                zone: zone,
                durationSeconds: Int(duration),
                percentage: round((duration / totalDuration) * 1000) / 10
            )
        }
    }

    // MARK: - Pause / Resume

    func pauseWorkout() {
        workoutSession?.pause()
    }

    func resumeWorkout() {
        workoutSession?.resume()
    }

    // MARK: - Statistics Update

    private func updateStatistics(_ statistics: HKStatistics) {
        DispatchQueue.main.async {
            switch statistics.quantityType {
            case HKQuantityType(.heartRate):
                let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
                if let value = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) {
                    self.heartRate = value
                    self.heartRateSamples.append((bpm: value, date: Date()))
                    if value > self.maxHeartRateValue {
                        self.maxHeartRateValue = value
                    }
                    self.updateHeartRateZone(value)

                    // Send realtime health data to iPhone
                    WatchSessionManager.shared.sendRealtimeHealth(
                        heartRate: value,
                        calories: self.activeCalories
                    )
                }

            case HKQuantityType(.activeEnergyBurned):
                let calorieUnit = HKUnit.kilocalorie()
                if let value = statistics.sumQuantity()?.doubleValue(for: calorieUnit) {
                    self.activeCalories = value
                }

            default:
                break
            }
        }
    }

    // MARK: - Heart Rate Zone

    private func updateHeartRateZone(_ heartRate: Double) {
        guard heartRate > 0 else { return }
        let newZone = HeartRateZone.zone(for: heartRate)
        let previousZone = currentZone
        currentZone = newZone

        if newZone != previousZone && newZone.rawValue >= 4 {
            HapticManager.heartRateZoneAlert()
        }
    }

    func reset() {
        heartRate = 0
        activeCalories = 0
        summaryHeartRate = 0
        summaryCalories = 0
        summaryMaxHeartRate = 0
        isWorkoutActive = false
        currentZone = .zone1
        heartRateSamples.removeAll()
        maxHeartRateValue = 0
        workoutSession = nil
        workoutBuilder = nil
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            self.isWorkoutActive = (toState == .running)
        }

        if toState == .ended {
            workoutBuilder?.endCollection(withEnd: date) { [weak self] success, error in
                self?.workoutBuilder?.finishWorkout { workout, error in
                    DispatchQueue.main.async {
                        self?.reset()
                    }
                }
            }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("[WorkoutManager] Session error: \(error.localizedDescription)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType,
                  let statistics = workoutBuilder.statistics(for: quantityType)
            else { continue }
            updateStatistics(statistics)
        }
    }
}
