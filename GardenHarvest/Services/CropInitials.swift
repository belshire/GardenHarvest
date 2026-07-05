extension String {
    /// Two-letter uppercase initials for a crop name, matching the design
    /// prototype's `ini()` — letters only, with "?" when the name has none.
    var cropInitials: String {
        let letters = String(filter(\.isLetter).prefix(2)).uppercased()
        return letters.isEmpty ? "?" : letters
    }
}
