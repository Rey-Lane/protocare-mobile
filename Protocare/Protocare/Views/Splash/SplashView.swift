import SwiftUI

struct SplashView: View {
    @State private var iconOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.appBackground, Color.appPrimaryLight],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Wave layers at the bottom
                VStack {
                    Spacer()
                    WaveView()
                        .frame(height: 320)
                }
                .ignoresSafeArea()

                // Logo area — centered slightly above middle
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: geometry.size.height * 0.22)

                    // App icon in squircle
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 112, height: 112)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .shadow(color: Color.appPrimary.opacity(0.4), radius: 18, y: 8)
                        .offset(y: iconOffset)

                    Text("Protocare")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.appText)

                    Text("Your daily care ritual")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color.appTextSecondary)
                        .padding(.top, -12)

                    Spacer()

                    // Bottom signature
                    VStack(spacing: 6) {
                        Text("Powered by Auren Terrix")
                            .font(.system(size: 11, weight: .semibold))
                            .kerning(1.5)
                            .foregroundStyle(Color.white.opacity(0.85))

                        Text("Self-care, simplified")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                    .padding(.bottom, 48)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    iconOffset = -6
                }
            }
        }
    }
}

// MARK: - Animated wave layers

private struct WaveView: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let w = size.width
                let h = size.height

                // Three wave layers — back to front
                let waves: [(color: Color, opacity: Double, amplitude: CGFloat, yBase: CGFloat, speed: Double, frequency: CGFloat)] = [
                    (Color.appPrimary, 0.35, 18, h * 0.25, 0.3, 1.2),
                    (Color.appPrimary, 0.55, 14, h * 0.40, 0.5, 1.5),
                    (Color.appPrimaryDark, 0.85, 10, h * 0.55, 0.7, 1.8),
                ]

                for wave in waves {
                    let path = wavePath(
                        width: w,
                        height: h,
                        amplitude: wave.amplitude,
                        yBase: wave.yBase,
                        frequency: wave.frequency,
                        time: t * wave.speed
                    )
                    context.fill(
                        path,
                        with: .color(wave.color.opacity(wave.opacity))
                    )
                }
            }
        }
    }

    private func wavePath(
        width: CGFloat,
        height: CGFloat,
        amplitude: CGFloat,
        yBase: CGFloat,
        frequency: CGFloat,
        time: Double
    ) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: height))

        let step: CGFloat = 2
        for x in stride(from: CGFloat(0), through: width, by: step) {
            let relativeX = x / width
            let y = yBase
                + sin(relativeX * .pi * 2 * frequency + CGFloat(time)) * amplitude
                + sin(relativeX * .pi * 2 * frequency * 0.5 + CGFloat(time) * 1.3) * amplitude * 0.5
            if x == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        return path
    }
}

#Preview {
    SplashView()
}
