import Testing
@testable import GardenHarvest

struct WeightFormatterTests {
    @Test func ouncesDropsTrailingZeroDecimal() {
        #expect(WeightFormatter.ounces(5.0) == "5")
        #expect(WeightFormatter.ounces(5.5) == "5.5")
        #expect(WeightFormatter.ounces(5.25) == "5.3")
    }

    @Test func poundsAndOuncesBelow16StaysInOunces() {
        #expect(WeightFormatter.poundsAndOunces(15.9) == "15.9 oz")
    }

    @Test func poundsAndOuncesAtExactPoundDropsOzPart() {
        #expect(WeightFormatter.poundsAndOunces(32) == "2 lb")
    }

    @Test func poundsAndOuncesWithRemainder() {
        #expect(WeightFormatter.poundsAndOunces(40.1) == "2 lb 8.1 oz")
    }
}
