import Testing
import Foundation
@testable import GardenHarvest

struct DateChipTests {
    @Test func todayReturnsStartOfReferenceDay() {
        var components = DateComponents()
        components.year = 2026; components.month = 7; components.day = 4; components.hour = 15
        let calendar = Calendar(identifier: .gregorian)
        let reference = calendar.date(from: components)!

        let result = DateChip.today.date(from: reference, calendar: calendar)
        let resultComponents = calendar.dateComponents([.year, .month, .day, .hour], from: result)
        #expect(resultComponents.year == 2026)
        #expect(resultComponents.month == 7)
        #expect(resultComponents.day == 4)
        #expect(resultComponents.hour == 0)
    }

    @Test func yesterdaySubtractsOneDay() {
        var components = DateComponents()
        components.year = 2026; components.month = 7; components.day = 4
        let calendar = Calendar(identifier: .gregorian)
        let reference = calendar.date(from: components)!

        let result = DateChip.yesterday.date(from: reference, calendar: calendar)
        let resultComponents = calendar.dateComponents([.year, .month, .day], from: result)
        #expect(resultComponents.day == 3)
    }

    @Test func customUsesPickedDateStartOfDay() {
        var picked = DateComponents()
        picked.year = 2026; picked.month = 6; picked.day = 20; picked.hour = 14
        let calendar = Calendar(identifier: .gregorian)
        let customDate = calendar.date(from: picked)!

        var referenceComponents = DateComponents()
        referenceComponents.year = 2026; referenceComponents.month = 7; referenceComponents.day = 4
        let reference = calendar.date(from: referenceComponents)!

        let result = DateChip.custom.date(customDate: customDate, from: reference, calendar: calendar)
        let resultComponents = calendar.dateComponents([.year, .month, .day, .hour], from: result)
        #expect(resultComponents.year == 2026)
        #expect(resultComponents.month == 6)
        #expect(resultComponents.day == 20)
        #expect(resultComponents.hour == 0)
    }
}
