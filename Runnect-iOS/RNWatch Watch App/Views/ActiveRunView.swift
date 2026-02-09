//
//  ActiveRunView.swift
//  RNWatch Watch App
//
//  Created by Runnect on 2026/02/08.
//

import SwiftUI

struct ActiveRunView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager
    @EnvironmentObject var workoutManager: WorkoutManager

    @State private var showKilometerAlert = false
    @State private var alertKm = 0
    @State private var alertPace = 0
    @State private var showEndConfirmation = false

    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                // Distance (primary, largest)
                VStack(spacing: 2) {
                    Text("거리")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)

                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text(displayDistance)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.7)

                        Text("km")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }

                // Course progress bar
                if sessionManager.runningData.totalCourseDistance > 0 {
                    CourseProgressBar(
                        progress: sessionManager.runningData.progress,
                        currentDistance: sessionManager.runningData.distance,
                        totalDistance: sessionManager.runningData.totalCourseDistance
                    )
                    .padding(.horizontal, 8)
                }

                // Time and Pace row
                HStack(spacing: 16) {
                    VStack(spacing: 2) {
                        Text("시간")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)

                        Text(displayTime)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.7)
                    }

                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1, height: 28)

                    VStack(spacing: 2) {
                        Text("페이스")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)

                        Text(sessionManager.runningData.formattedPace)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.7)
                    }
                }

                // Heart rate bar
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundColor(heartRateZoneColor)

                    Text(heartRateText)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(heartRateZoneColor)

                    if workoutManager.heartRate > 0 {
                        Text(workoutManager.currentZone.shortLabel)
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(workoutManager.currentZone.color))
                    }

                    Spacer()

                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.runnectCalorie)

                    Text(caloriesText)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.runnectCalorie)
                }
                .padding(.horizontal, 8)

                // End running button
                Button {
                    showEndConfirmation = true
                } label: {
                    Text("러닝 종료")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.runnectPrimary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 4)

            // Kilometer alert overlay
            if showKilometerAlert {
                KilometerAlertView(kilometer: alertKm, pace: alertPace)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .background(Color.runnectBackground)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: summaryBinding) {
            RunSummaryView()
                .environmentObject(sessionManager)
                .environmentObject(workoutManager)
        }
        .confirmationDialog("러닝을 종료하시겠습니까?", isPresented: $showEndConfirmation, titleVisibility: .visible) {
            Button("종료", role: .destructive) {
                endRunning()
            }
            Button("취소", role: .cancel) {}
        }
        .onReceive(NotificationCenter.default.publisher(for: .kilometerReached)) { notification in
            if let km = notification.userInfo?["km"] as? Int,
               let pace = notification.userInfo?["pace"] as? Int {
                alertKm = km
                alertPace = pace
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    showKilometerAlert = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showKilometerAlert = false
                    }
                }
            }
        }
    }

    // MARK: - Display Properties

    private var displayDistance: String {
        sessionManager.runningData.formattedDistance
    }

    private var displayTime: String {
        // Use iPhone data if available, fallback to local timer
        if sessionManager.isReachable {
            return sessionManager.runningData.formattedTime
        } else {
            return WatchTimeFormatter.secondsToHHMMSS(seconds: sessionManager.localElapsedTime)
        }
    }

    private var heartRateZoneColor: Color {
        workoutManager.heartRate > 0 ? workoutManager.currentZone.color : .runnectHeartRate
    }

    private var heartRateText: String {
        let hr = Int(workoutManager.heartRate)
        return hr > 0 ? "\(hr)" : "--"
    }

    private var caloriesText: String {
        let cal = Int(workoutManager.activeCalories)
        return "\(cal) kcal"
    }

    private var summaryBinding: Binding<Bool> {
        Binding(
            get: { sessionManager.runningState == .summary },
            set: { if !$0 { sessionManager.runningState = .idle } }
        )
    }

    // MARK: - Actions

    private func endRunning() {
        workoutManager.endWorkout()
        sessionManager.stopLocalTimer()
        sessionManager.sendRunCommand("endRunning")
        sessionManager.runningState = .summary
    }
}
