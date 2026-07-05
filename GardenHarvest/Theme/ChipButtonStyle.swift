import SwiftUI

struct ChipButtonStyle: ButtonStyle {
    var isSelected: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Font.mono(13, weight: .heavy))
            .foregroundStyle(isSelected ? .white : Theme.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(isSelected ? Theme.accent : Theme.card)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isSelected ? Theme.accent : Theme.hairline, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
