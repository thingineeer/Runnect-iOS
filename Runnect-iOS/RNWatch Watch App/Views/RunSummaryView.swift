//
//  RunSummaryView.swift
//  RNWatch Watch App
//
//  Created by 이명진 on 2026/02/08.
//

import SwiftUI

struct RunSummaryView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager
    @EnvironmentObject var workoutManager: WorkoutManager

    private var data: WatchRunningData {
        sessionManager.runningData
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header
                Image(systemName: "flag.checkered")
                    .font(.system(size: 28))
                    .foregroundColor(.runnectPrimary)

                Text("러닝 완료")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                // Distance with achievement
                VStack(spacing: 4) {
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text(data.formattedDistance)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.runnectPrimary)

                        Text("km")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }

                    if data.totalCourseDistance > 0 {
                        Text("달성률 \(Int(data.progress * 100))%")
                            .font(.system(size: 12))
                            .foregroundColor(.runnectSecondary)
                    }
                }

                // 2x2 stats grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    StatCell(title: "시간", value: data.formattedTime, color: .white)
                    StatCell(title: "페이스", value: data.formattedPace, color: .white)
                    HeartRateStatCell(
                        title: "평균 심박수",
                        heartRate: workoutManager.summaryHeartRate
                    )
                    StatCell(
                        title: "칼로리",
                        value: "\(Int(workoutManager.summaryCalories))",
                        color: .runnectCalorie
                    )
                }
                .padding(.horizontal, 4)

                // Done button
                Button {
                    sessionManager.resetRunning()
                    workoutManager.reset()
                } label: {
                    Text("확인")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.runnectPrimary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 8)
        }
        .background(Color.runnectBackground)
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - StatCell

private struct StatCell: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.gray)

            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(color)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - HeartRateStatCell

private struct HeartRateStatCell: View {
    let title: String
    let heartRate: Double

    private var zone: HeartRateZone {
        HeartRateZone.zone(for: heartRate)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.gray)

            HStack(spacing: 3) {
                Text(heartRate > 0 ? "\(Int(heartRate))" : "--")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.runnectHeartRate)
                    .minimumScaleFactor(0.7)

                if heartRate > 0 {
                    Text(zone.shortLabel)
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(zone.color))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
