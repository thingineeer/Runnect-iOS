//
//  WatchRunningData.swift
//  RNWatch Watch App
//
//  Created by 이명진 on 2026/02/08.
//

import Foundation

struct WatchRunningData {
    var distance: Double       // km
    var elapsedTime: Int       // seconds
    var pace: Int              // seconds per km
    var progress: Double       // 0.0 ~ 1.0, course completion ratio
    var totalCourseDistance: Double  // total course distance in km
    var isRunning: Bool
    var courseName: String

    var formattedDistance: String {
        String(format: "%.1f", distance)
    }

    var formattedTime: String {
        WatchTimeFormatter.secondsToHHMMSS(seconds: elapsedTime)
    }

    var formattedPace: String {
        guard pace > 0 else { return "--'--''" }
        return WatchTimeFormatter.paceString(secondsPerKm: pace)
    }

    var completedKilometers: Int {
        Int(distance)
    }

    static let empty = WatchRunningData(
        distance: 0,
        elapsedTime: 0,
        pace: 0,
        progress: 0,
        totalCourseDistance: 0,
        isRunning: false,
        courseName: ""
    )
}

// MARK: - WCSession Dictionary Conversion

extension WatchRunningData {
    enum Keys {
        static let distance = "distance"
        static let elapsedTime = "elapsedTime"
        static let pace = "pace"
        static let progress = "progress"
        static let totalCourseDistance = "totalCourseDistance"
        static let isRunning = "isRunning"
        static let courseName = "courseName"
        static let messageType = "messageType"
    }

    init?(from dictionary: [String: Any]) {
        guard let distance = dictionary[Keys.distance] as? Double,
              let elapsedTime = dictionary[Keys.elapsedTime] as? Int,
              let pace = dictionary[Keys.pace] as? Int,
              let progress = dictionary[Keys.progress] as? Double,
              let totalCourseDistance = dictionary[Keys.totalCourseDistance] as? Double,
              let isRunning = dictionary[Keys.isRunning] as? Bool,
              let courseName = dictionary[Keys.courseName] as? String
        else { return nil }

        self.distance = distance
        self.elapsedTime = elapsedTime
        self.pace = pace
        self.progress = progress
        self.totalCourseDistance = totalCourseDistance
        self.isRunning = isRunning
        self.courseName = courseName
    }

    func toDictionary() -> [String: Any] {
        return [
            Keys.messageType: "runningUpdate",
            Keys.distance: distance,
            Keys.elapsedTime: elapsedTime,
            Keys.pace: pace,
            Keys.progress: progress,
            Keys.totalCourseDistance: totalCourseDistance,
            Keys.isRunning: isRunning,
            Keys.courseName: courseName
        ]
    }
}
