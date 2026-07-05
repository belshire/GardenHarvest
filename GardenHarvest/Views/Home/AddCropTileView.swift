import SwiftUI

struct AddCropTileView: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Circle()
                    .strokeBorder(Theme.hairline, style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text("+")
                            .font(.system(size: 22))
                            .foregroundStyle(Theme.sub)
                    )
                Text("Add veg")
                    .font(Theme.Font.body(12, weight: .bold))
                    .foregroundStyle(Theme.sub)
            }
            .frame(minHeight: 104)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 6)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.tileRadius)
                    .strokeBorder(Theme.hairline, style: StrokeStyle(lineWidth: 1.5, dash: [4]))
            )
        }
        .buttonStyle(.plain)
    }
}
