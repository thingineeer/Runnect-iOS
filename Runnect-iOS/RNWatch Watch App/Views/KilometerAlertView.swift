//
//  KilometerAlertView.swift
//  RNWatch Watch App
//
//  Created by Runnect on 2026/02/08.
//

import SwiftUI

struct KilometerAlertView: View {
    let kilometer: Int
    let pace: Int

    @State private var checkmarkScale: CGFloat = 0.3
    @State private var checkmarkOpacity: Double = 0.0

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                // Checkmark with bounce animation
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.runnectPrimary)
                    .scaleEffect(checkmarkScale)
                    .opacity(checkmarkOpacity)

                // Kilometer text
                Text("\(kilometer) km")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                // Section pace
                if pace > 0 {
                    VStack(spacing: 2) {
                        Text("구간 페이스")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)

                        Text(WatchTimeFormatter.paceString(secondsPerKm: pace))
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.runnectSecondary)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0)) {
                checkmarkScale = 1.0
                checkmarkOpacity = 1.0
            }
        }
    }
}
