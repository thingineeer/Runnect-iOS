//
//  CountdownView.swift
//  RNWatch Watch App
//
//  Created by Runnect on 2026/02/08.
//

import SwiftUI

struct CountdownView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager
    @EnvironmentObject var workoutManager: WorkoutManager

    @State private var countdownValue = 3
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0
    @State private var isFinished = false
    @State private var countdownTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.runnectBackground
                .ignoresSafeArea()

            if !isFinished {
                Text("\(countdownValue)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(.runnectPrimary)
                    .scaleEffect(scale)
                    .opacity(opacity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $isFinished) {
            ActiveRunView()
                .environmentObject(sessionManager)
                .environmentObject(workoutManager)
        }
        .onAppear {
            startCountdown()
        }
        .onDisappear {
            countdownTask?.cancel()
            countdownTask = nil
        }
    }

    private func startCountdown() {
        countdownTask?.cancel()
        countdownTask = Task { @MainActor in
            animateNumber()

            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            countdownValue = 2
            animateNumber()

            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            countdownValue = 1
            animateNumber()

            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            workoutManager.startWorkout()
            sessionManager.startLocalTimer()
            isFinished = true
        }
    }

    private func animateNumber() {
        scale = 0.5
        opacity = 0.0
        withAnimation(.easeOut(duration: 0.4)) {
            scale = 1.2
            opacity = 1.0
        }
        withAnimation(.easeIn(duration: 0.3).delay(0.5)) {
            scale = 0.8
            opacity = 0.0
        }
    }
}
