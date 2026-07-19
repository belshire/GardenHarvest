/// Every VegIcons slug offered in the icon picker. Cornucopia is excluded —
/// it is the "All crops" filter symbol, not a crop icon. Kept in sync with
/// `CropIconAssigner.iconMap` by `IconCatalogTests`.
enum IconCatalog {
    static let allSlugs: [String] = [
        "apple", "artichoke", "arugula", "asparagus", "avocado", "banana",
        "basil", "beet", "blackberry", "blueberries", "broccoli",
        "brussels-sprout", "butternut-squash", "cabbage", "cantaloupe",
        "carrot", "cauliflower", "celeriac", "champignon-mushroom",
        "cherry-tomatoes", "chili-pepper", "corn", "cucumber", "daikon",
        "edamame", "eggplant", "garlic", "ginger", "green-beans", "kale",
        "kiwi", "leek", "lime", "mango", "onion", "orange",
        "orange-bell-pepper", "oyster-mushroom", "parsnip", "passion-fruit",
        "pear", "peas", "pomegranate", "porcini-mushroom", "potato",
        "pumpkin", "purple-daikon", "radish", "raspberry", "red-bell-pepper",
        "red-onion", "shiitake-mushroom", "spinach", "strawberry",
        "sweet-potato", "tomato", "turmeric", "turnip", "watermelon",
        "white-radish", "zucchini"
    ]

    static func assetName(for slug: String) -> String { "VegIcons/\(slug)" }

    /// "red-bell-pepper" -> "Red Bell Pepper", for search and accessibility.
    static func displayName(for slug: String) -> String {
        slug.split(separator: "-").map(\.capitalized).joined(separator: " ")
    }
}
