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

    // Summary values preserved after workout ends
    @Published var summaryHeartRate: Double = 0
    @Published var summaryCalories: Double = 0

    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?

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

        // Use averageQuantity for heart rate if available
        if let builder = workoutBuilder,
           let hrStats = builder.statistics(for: HKQuantityType(.heartRate)) {
            let hrUnit = HKUnit.count().unitDivided(by: .minute())
            if let avg = hrStats.averageQuantity()?.doubleValue(for: hrUnit) {
                summaryHeartRate = avg
            }
        }

        workoutSession?.end()

        DispatchQueue.main.async {
            self.isWorkoutActive = false
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

    func reset() {
        heartRate = 0
        activeCalories = 0
        summaryHeartRate = 0
        summaryCalories = 0
        isWorkoutActive = false
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
