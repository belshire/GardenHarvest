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

    @Test func twoDaysAgoSubtractsTwoDays() {
        var components = DateComponents()
        components.year = 2026; components.month = 7; components.day = 4
        let calendar = Calendar(identifier: .gregorian)
        let reference = calendar.date(from: components)!

        let result = DateChip.twoDaysAgo.date(from: reference, calendar: calendar)
        let resultComponents = calendar.dateComponents([.year, .month, .day], from: result)
        #expect(resultComponents.day == 2)
    }
}
