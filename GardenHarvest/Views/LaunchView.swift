import SwiftUI

/// "Waking the garden" launch screen: journal, serif wordmark,
/// and rising harvest dots while data loads.
struct LaunchView: View {
    /// Renders the static pose without animating (and with no dots). Used to
    /// generate the static system launch image so the handoff into the live
    /// view is seamless.
    var frozen = false

    private let dotPeriod: Double = 1.4
    /// Phase the dot clock starts at, chosen so the first live frame shows
    /// all three dots mid-rise.
    private let posePhase: Double = 0.7
    /// How long the dots row takes to fade in when the live view appears.
    private let dotsFadeIn: Double = 0.35

    @State private var start = Date()

    var body: some View {
        TimelineView(.animation(paused: frozen)) { timeline in
            let elapsed = frozen ? 0 : timeline.date.timeIntervalSince(start)
            let t = elapsed + posePhase

            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "#f4faec"), location: 0),
                        .init(color: Color(hex: "#e2f2d3"), location: 0.46),
                        .init(color: Color(hex: "#cfe6c4"), location: 1)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                GeometryReader { geo in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.7), Color.white.opacity(0)],
                                center: .center, startRadius: 0, endRadius: 170
                            )
                        )
                        .frame(width: 340, height: 340)
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.16 + 170)
                }
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.white.opacity(0.55), Color.white.opacity(0)],
                                    center: .center, startRadius: 0, endRadius: 117
                                )
                            )
                            .frame(width: 234, height: 234)

                        Image("TabIcons/notebook")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 186)
                            .shadow(color: Color(hex: "#1e3214").opacity(0.26), radius: 13, x: 0, y: 22)
                    }

                    Text("Garden\nHarvest")
                        .font(Theme.Font.heading(38))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                        .lineSpacing(38 * 0.02)
                        .padding(.top, 36)

                    Text("TEND · PICK · LOG")
                        .font(Theme.Font.mono(12))
                        .tracking(3.4)
                        .foregroundStyle(Theme.sub)
                        .padding(.top, 14)
                }
                .padding(.horizontal, 40)

                if !frozen {
                    VStack {
                        Spacer()
                        HStack(spacing: 9) {
                            dot(Theme.accent, t: t, delay: 0)
                            dot(Theme.accent2, t: t, delay: 0.18)
                            dot(Theme.accent, t: t, delay: 0.36)
                        }
                        .padding(.bottom, 96)
                    }
                    .opacity(min(1, elapsed / dotsFadeIn))
                }
            }
        }
    }

    private func dot(_ color: Color, t: Double, delay: Double) -> some View {
        let phase = wrap(t - delay, period: dotPeriod)
        let y = 6 - 12 * phase
        let opacity = phase < 0.5 ? 0.2 + 1.6 * phase : 1.8 - 1.6 * phase
        return Circle()
            .fill(color)
            .frame(width: 7, height: 7)
            .offset(y: y)
            .opacity(opacity)
    }

    /// Normalized [0, 1) phase that stays continuous for negative inputs,
    /// so staggered dots have a well-defined pose at t = 0.
    private func wrap(_ t: Double, period: Double) -> Double {
        let r = t.truncatingRemainder(dividingBy: period)
        return (r < 0 ? r + period : r) / period
    }
}

#Preview {
    LaunchView()
}
