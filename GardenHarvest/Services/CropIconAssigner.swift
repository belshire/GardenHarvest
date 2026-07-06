enum CropIconAssigner {
    /// Ports the prototype's `ICON_MAP`: lowercased crop name -> icon slug in the
    /// `VegIcons` asset namespace. Extended with the icons that ship in
    /// `vegetable-icons/individual-icons` but weren't mapped in the prototype
    /// (orange bell pepper, porcini mushroom, purple daikon, white radish).
    static let iconMap: [String: String] = [
        "asparagus": "asparagus", "strawberries": "strawberry", "strawberry": "strawberry",
        "raspberries": "raspberry", "raspberry": "raspberry", "blueberries": "blueberries", "blueberry": "blueberries",
        "boysenberries": "blackberry", "blackberries": "blackberry", "blackberry": "blackberry",
        "artichoke": "artichoke", "artichokes": "artichoke", "radishes": "radish", "radish": "radish",
        "peas": "peas", "pea": "peas", "snap peas": "peas", "snow peas": "peas",
        "mushrooms": "champignon-mushroom", "mushroom": "champignon-mushroom",
        "shiitake": "shiitake-mushroom", "shiitake mushroom": "shiitake-mushroom", "shiitake mushrooms": "shiitake-mushroom",
        "oyster mushroom": "oyster-mushroom", "oyster mushrooms": "oyster-mushroom",
        "porcini": "porcini-mushroom", "porcini mushroom": "porcini-mushroom", "porcini mushrooms": "porcini-mushroom",
        "tomatoes cherry": "cherry-tomatoes", "cherry tomatoes": "cherry-tomatoes", "cherry tomato": "cherry-tomatoes",
        "tomatoes": "tomato", "tomato": "tomato", "cucumber": "cucumber", "cucumbers": "cucumber",
        "zucchini": "zucchini", "courgette": "zucchini", "kale": "kale", "carrots": "carrot", "carrot": "carrot",
        "green beans": "green-beans", "beans": "green-beans", "string beans": "green-beans",
        "peppers": "chili-pepper", "pepper": "chili-pepper", "chili": "chili-pepper", "chilli": "chili-pepper",
        "bell peppers": "red-bell-pepper", "bell pepper": "red-bell-pepper",
        "orange bell pepper": "orange-bell-pepper", "orange bell peppers": "orange-bell-pepper",
        "squash": "butternut-squash", "butternut": "butternut-squash", "basil": "basil", "corn": "corn",
        "onions": "onion", "onion": "onion", "red onion": "red-onion", "red onions": "red-onion", "garlic": "garlic",
        "potatoes": "potato", "potato": "potato", "beets": "beet", "beet": "beet", "beetroot": "beet",
        "spinach": "spinach", "broccoli": "broccoli", "cauliflower": "cauliflower", "cabbage": "cabbage",
        "eggplant": "eggplant", "aubergine": "eggplant", "apples": "apple", "apple": "apple",
        "pears": "pear", "pear": "pear", "melon": "cantaloupe", "watermelon": "watermelon", "cantaloupe": "cantaloupe",
        "pumpkin": "pumpkin", "pumpkins": "pumpkin", "leeks": "leek", "leek": "leek",
        "celery": "celeriac", "celeriac": "celeriac",
        "turnips": "turnip", "turnip": "turnip", "parsnips": "parsnip", "parsnip": "parsnip",
        "sweet potatoes": "sweet-potato", "sweet potato": "sweet-potato", "arugula": "arugula", "rocket": "arugula",
        "avocado": "avocado", "avocados": "avocado", "banana": "banana", "bananas": "banana", "edamame": "edamame",
        "ginger": "ginger", "kiwi": "kiwi", "lime": "lime", "limes": "lime", "mango": "mango", "mangoes": "mango",
        "orange": "orange", "oranges": "orange", "pomegranate": "pomegranate", "passion fruit": "passion-fruit",
        "brussels sprouts": "brussels-sprout", "brussel sprouts": "brussels-sprout",
        "daikon": "daikon", "purple daikon": "purple-daikon", "white radish": "white-radish", "turmeric": "turmeric"
    ]

    /// Ports the prototype's `iconFor(name)`: exact lookup first, then the longest
    /// substring match (either direction, keys of 3+ characters). Returns the asset
    /// catalog name, or nil when the crop has no icon and should fall back to initials.
    static func assetName(for cropName: String) -> String? {
        let key = cropName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return nil }
        if let slug = iconMap[key] {
            return "VegIcons/\(slug)"
        }
        var best: String?
        var bestLength = 0
        // Sorted so ties on length resolve the same way every launch.
        for (candidate, slug) in iconMap.sorted(by: { $0.key < $1.key }) {
            guard candidate.count >= 3, candidate.count > bestLength else { continue }
            if key.contains(candidate) || candidate.contains(key) {
                best = slug
                bestLength = candidate.count
            }
        }
        return best.map { "VegIcons/\($0)" }
    }
}
