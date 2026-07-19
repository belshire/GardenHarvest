import UIKit

enum IconImageProcessor {
    /// Center-crops the image square, scales it to `side`×`side` pixels, and
    /// JPEG-encodes it for storage in `Crop.customIconData`. Returns nil when
    /// the data isn't a decodable image.
    static func squareIconData(from data: Data, side: CGFloat = 512) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let shortest = min(image.size.width, image.size.height)
        guard shortest > 0 else { return nil }

        let scale = side / shortest
        let origin = CGPoint(
            x: -(image.size.width - shortest) / 2 * scale,
            y: -(image.size.height - shortest) / 2 * scale
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let squared = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
            .image { _ in
                image.draw(in: CGRect(
                    origin: origin,
                    size: CGSize(width: image.size.width * scale, height: image.size.height * scale)
                ))
            }
        return squared.jpegData(compressionQuality: 0.85)
    }
}
