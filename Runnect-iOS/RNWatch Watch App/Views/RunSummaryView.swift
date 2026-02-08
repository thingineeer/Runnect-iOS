//
//  RunSummaryView.swift
//  RNWatch Watch App
//
//  Created by Runnect on 2026/02/08.
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
                    StatCell(
                        title: "평균 심박수",
                        value: workoutManager.summaryHeartRate > 0 ? "\(Int(workoutManager.summaryHeartRate))" : "--",
                        color: .runnectHeartRate
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
