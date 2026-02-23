//
//  CourseProgressBar.swift
//  RNWatch Watch App
//
//  Created by 이명진 on 2026/02/09.
//

import SwiftUI

struct CourseProgressBar: View {
    let progress: Double
    let currentDistance: Double
    let totalDistance: Double

    private let barHeight: CGFloat = 5
    private let markerSize: CGFloat = 10
    private let runnerSize: CGFloat = 14

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                let barWidth = geometry.size.width
                let clampedProgress = min(max(progress, 0), 1)
                let runnerX = barWidth * clampedProgress

                ZStack(alignment: .leading) {
                    // Background bar (unfilled)
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: barHeight)

                    // Filled bar (progress)
                    Capsule()
                        .fill(Color.runnectPrimary)
                        .frame(width: max(barWidth * clampedProgress, 0), height: barHeight)

                    // Start marker "S"
                    Text("S")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: markerSize, height: markerSize)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.6))
                        )
                        .position(x: markerSize / 2, y: barHeight / 2)

                    // Runner marker
                    Image(systemName: "figure.run")
                        .font(.system(size: runnerSize, weight: .semibold))
                        .foregroundColor(.runnectPrimary)
                        .position(
                            x: min(max(runnerX, markerSize), barWidth - markerSize),
                            y: barHeight / 2
                        )
                        .animation(.easeInOut(duration: 0.5), value: clampedProgress)

                    // End marker "E"
                    Image(systemName: "flag.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.white)
                        .frame(width: markerSize, height: markerSize)
                        .position(x: barWidth - markerSize / 2, y: barHeight / 2)
                }
            }
            .frame(height: max(runnerSize, markerSize))

            // Distance text
            Text("\(String(format: "%.1f", currentDistance)) / \(String(format: "%.1f", totalDistance)) km")
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.gray)
        }
    }
}
