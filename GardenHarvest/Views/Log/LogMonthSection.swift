import SwiftUI
import SwiftData

/// One collapsible month in the Log: a header row with the month's share bar
/// and total, and — when expanded — day labels with their picking rows.
/// Tapping a picking row reveals inline Edit/Delete actions beneath it.
struct LogMonthSection: View {
    let group: LogGrouping.MonthGroup
    /// Month total relative to the year's biggest month, 0...1 (floored by caller).
    let fillFraction: Double
    /// Green by default; the crop's color when the Log is filtered to one crop.
    let barFill: Color
    let isExpanded: Bool
    /// The entry whose action bar is showing (at most one across the Log).
    let revealedEntryID: PersistentIdentifier?
    let colorHex: (String) -> String
    let resolveIcon: (String) -> ResolvedCropIcon
    let onToggle: () -> Void
    let onRowTap: (HarvestEntry) -> Void
    let onEdit: (HarvestEntry) -> Void
    let onDelete: (HarvestEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(group.days, id: \.date) { day in
                        dayLabel(day.date)
                        ForEach(day.entries) { entry in
                            if revealedEntryID == entry.id {
                                revealedRow(entry)
                            } else {
                                Button {
                                    onRowTap(entry)
                                } label: {
                                    pickingRow(entry)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.leading, 2)
            }
        }
    }

    /// A tapped row and its Edit/Delete actions, grouped under one soft
    /// highlight (no divider between them) so it's unambiguous which entry
    /// the buttons belong to, even mid-list.
    private func revealedRow(_ entry: HarvestEntry) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                onRowTap(entry)
            } label: {
                pickingRow(entry, showsDivider: false)
            }
            .buttonStyle(.plain)
            HStack(spacing: 8) {
                Spacer()
                actionButton("Edit", icon: "pencil", tint: Theme.accent) { onEdit(entry) }
                actionButton("Delete", icon: "trash", tint: Color(hex: "#c0392b")) { onDelete(entry) }
            }
            .padding(.top, 2)
            .padding(.bottom, 11)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.accent.opacity(0.07))
                .padding(.horizontal, -8)
        )
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.hairline).frame(height: 1)
        }
    }

    private func actionButton(_ label: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(Theme.Font.body(12.5, weight: .bold))
                .foregroundStyle(tint)
                .padding(.vertical, 7)
                .padding(.horizontal, 13)
                .background(tint.opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        Button(action: onToggle) {
            HStack(spacing: 0) {
                Text(monthName)
                    .font(Theme.Font.heading(18))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 96, alignment: .leading)
                CapsuleBar(fraction: fillFraction, fill: barFill)
                    .frame(height: 8)
                    .padding(.horizontal, 12)
                Text(WeightFormatter.poundsAndOunces(group.total))
                    .font(Theme.Font.mono(12, weight: .bold))
                    .foregroundStyle(Theme.accent)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.sub)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .padding(.leading, 10)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(Theme.card)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color(hex: "#1e3214").opacity(0.08), radius: 9, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var monthName: String {
        Calendar.current.monthSymbols[group.month - 1]
    }

    private func dayLabel(_ date: Date) -> some View {
        Text(Self.dayFormatter.string(from: date))
            .font(Theme.Font.mono(11, weight: .heavy))
            .textCase(.uppercase)
            .tracking(1)
            .foregroundStyle(Theme.sub)
            .padding(.top, 8)
    }

    private func pickingRow(_ entry: HarvestEntry, showsDivider: Bool = true) -> some View {
        HStack(spacing: 12) {
            CropIconPlate(
                cropName: entry.cropName,
                colorHex: colorHex(entry.cropName),
                plateSize: 38,
                iconSize: 30,
                discSize: 34,
                resolvedIcon: resolveIcon(entry.cropName)
            )
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.cropName)
                    .font(Theme.Font.heading(14.5, weight: .bold))
                    .foregroundStyle(Theme.ink)
                if let note = displayNote(entry) {
                    Text(note)
                        .font(Theme.Font.body(11.5))
                        .italic()
                        .foregroundStyle(Theme.sub)
                }
            }
            Spacer()
            Text("\(WeightFormatter.ounces(entry.ounces)) oz")
                .font(Theme.Font.mono(14, weight: .heavy))
                .foregroundStyle(Theme.ink)
        }
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            if showsDivider {
                Rectangle().fill(Theme.hairline).frame(height: 1)
            }
        }
        // The row is a button; without an explicit shape the transparent
        // stretch around the Spacer isn't hit-testable.
        .contentShape(Rectangle())
    }

    /// Variant and free-form note joined as in the design, e.g. "large · some woody".
    private func displayNote(_ entry: HarvestEntry) -> String? {
        let parts = [entry.variant, entry.note].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d"
        return formatter
    }()
}
