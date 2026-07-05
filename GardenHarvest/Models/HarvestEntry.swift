import Foundation
import SwiftData

@Model
final class HarvestEntry {
    var cropName: String
    var ounces: Double
    var date: Date
    var note: String
    var variant: String?
    var photoData: Data?
    var photoSource: String?

    init(
        cropName: String,
        ounces: Double,
        date: Date,
        note: String = "",
        variant: String? = nil,
        photoData: Data? = nil,
        photoSource: String? = nil
    ) {
        self.cropName = cropName
        self.ounces = ounces
        self.date = date
        self.note = note
        self.variant = variant
        self.photoData = photoData
        self.photoSource = photoSource
    }
}
