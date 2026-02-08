//
//  RunningIdleView.swift
//  RNWatch Watch App
//
//  Created by Runnect on 2026/02/08.
//

import SwiftUI

struct RunningIdleView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager
    @EnvironmentObject var workoutManager: WorkoutManager

    var body: some View {
        VStack(spacing: 12) {
            // Connection status
            HStack(spacing: 6) {
                Circle()
                    .fill(sessionManager.isReachable ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)

                Text(sessionManager.isReachable ? "iPhone 연결됨" : "연결 대기 중")
                    .font(.system(size: 12))
                    .foregroundColor(sessionManager.isReachable ? .white : .gray)
            }

            Spacer()

            // App logo area
            Image(systemName: "figure.run")
                .font(.system(size: 36))
                .foregroundColor(.runnectPrimary)

            Text("Runnect")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            // Last running summary (if available)
            if sessionManager.runningData.distance > 0 && sessionManager.runningState == .idle {
                VStack(spacing: 4) {
                    Text("최근 러닝")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)

                    Text("\(sessionManager.runningData.formattedDistance) km")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.runnectSecondary)
                }
                .padding(.top, 4)
            }

            Spacer()

            // Status text
            Text("iPhone에서 러닝을 시작하세요")
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.runnectBackground)
        .navigationDestination(isPresented: countdownBinding) {
            CountdownView()
                .environmentObject(sessionManager)
                .environmentObject(workoutManager)
        }
        .onAppear {
            workoutManager.requestAuthorization()
        }
    }

    private var countdownBinding: Binding<Bool> {
        Binding(
            get: { sessionManager.runningState == .countdown || sessionManager.runningState == .active || sessionManager.runningState == .summary },
            set: { if !$0 { sessionManager.runningState = .idle } }
        )
    }
}
