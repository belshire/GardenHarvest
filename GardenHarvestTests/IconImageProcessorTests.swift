import UIKit
import Testing
@testable import GardenHarvest

struct IconImageProcessorTests {
    /// Renders a solid-color image of the given size and returns its PNG data.
    private func imageData(width: CGFloat, height: CGFloat) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
            .image { context in
                UIColor.systemGreen.setFill()
                context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            }
        return image.pngData()!
    }

    @Test func landscapeImageBecomesSquareAtTargetSide() {
        let out = IconImageProcessor.squareIconData(from: imageData(width: 1000, height: 600))
        let image = out.flatMap(UIImage.init(data:))
        #expect(image != nil)
        #expect(image!.size.width * image!.scale == 512)
        #expect(image!.size.height * image!.scale == 512)
    }

    @Test func portraitAndSmallImagesAlsoBecomeSquare() {
        let out = IconImageProcessor.squareIconData(from: imageData(width: 60, height: 100))
        let image = out.flatMap(UIImage.init(data:))
        #expect(image!.size.width * image!.scale == 512)
        #expect(image!.size.height * image!.scale == 512)
    }

    @Test func garbageDataReturnsNil() {
        #expect(IconImageProcessor.squareIconData(from: Data([0x00, 0x01])) == nil)
    }
}
