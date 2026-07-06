import Foundation

/// Per-season insight cache in UserDefaults. Keyed by a fingerprint of the
/// season's entries so any add / edit / delete invalidates the cache — the
/// deck regenerates whenever the data changes, never on a timer.
enum InsightStore {
    struct Cached: Codable, Equatable {
        let fingerprint: String
        let insights: [Insight]
        /// True once the on-device model has reworded the templates, so we
        /// don't re-run generation for unchanged data.
        let aiComposed: Bool
    }

    /// Order-independent FNV-1a hash over every entry's crop, ounces, date,
    /// and variant, so moving weight between crops or editing a date invalidates
    /// even when count and grand total stay the same.
    static func fingerprint(of entries: [HarvestEntry]) -> String {
        var hash: UInt64 = 0xcbf29ce484222325
        let lines = entries
            .map { "\($0.cropName)|\($0.ounces)|\($0.date.timeIntervalSince1970)|\($0.variant ?? "")" }
            .sorted()
        for line in lines {
            for byte in line.utf8 {
                hash ^= UInt64(byte)
                hash = hash &* 0x100000001b3
            }
            hash ^= 0x0A
            hash = hash &* 0x100000001b3
        }
        return String(hash, radix: 16)
    }

    static func load(season: Int, defaults: UserDefaults = .standard) -> Cached? {
        guard let data = defaults.data(forKey: key(for: season)) else { return nil }
        return try? JSONDecoder().decode(Cached.self, from: data)
    }

    static func save(_ cached: Cached, season: Int, defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(cached) else { return }
        defaults.set(data, forKey: key(for: season))
    }

    private static func key(for season: Int) -> String {
        "insights.season.\(season)"
    }
}
