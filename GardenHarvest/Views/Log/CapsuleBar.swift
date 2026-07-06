import SwiftUI

/// Rounded progress track used by the Log's month headers and the crop
/// dossier's year rows.
struct CapsuleBar: View {
    /// Filled portion, 0...1. Callers apply any minimum-width floor.
    let fraction: Double
    let fill: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.hairline)
                Capsule()
                    .fill(fill)
                    .frame(width: geo.size.width * min(max(fraction, 0), 1))
            }
        }
    }
}
