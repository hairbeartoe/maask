import UIKit
import SwiftUI

// Flattens the image and emoji overlays into a single UIImage
class ImageComposer {
    static func compose(image: UIImage, masks: [EmojiMask], displaySize: CGSize) -> UIImage? {
        let imageSize = image.size
        
        // Calculate the scale factor between display and actual image
        let displayScale = min(displaySize.width / imageSize.width, displaySize.height / imageSize.height)
        let sizeScaleFactor = 1.0 / displayScale
        
        print("=== Scaling Debug ===")
        print("Image size: \(imageSize)")
        print("Display size: \(displaySize)")
        print("Display scale: \(displayScale)")
        print("Size scale factor: \(sizeScaleFactor)")
        print("====================")

        // Create graphics context at full image resolution
        UIGraphicsBeginImageContextWithOptions(imageSize, false, image.scale)
        
        // Draw the original image
        image.draw(in: CGRect(origin: .zero, size: imageSize))

        for mask in masks {
            let emoji = mask.emoji
            // FIXED: Scale the emoji size for full resolution
            let scaledEmojiSize = mask.size * sizeScaleFactor
            let font = UIFont.systemFont(ofSize: scaledEmojiSize)
            let attr: [NSAttributedString.Key: Any] = [.font: font]
            let textSize = emoji.size(withAttributes: attr)
            
            // Center the emoji at the mask's center point (coordinates are already in image space)
            let drawPoint = CGPoint(
                x: mask.center.x - textSize.width / 2,
                y: mask.center.y - textSize.height / 2
            )
            
            print("Mask: original size=\(mask.size), scaled size=\(scaledEmojiSize)")
            
            emoji.draw(at: drawPoint, withAttributes: attr)
        }
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
    
}

/* 
DEBUGGING HELPER: Add this method to help debug size issues
*/
extension ImageComposer {
    static func debugMaskSizes(image: UIImage, masks: [EmojiMask]) {
        print("=== Debug Info ===")
        print("Image size: \(image.size)")
        print("Image scale: \(image.scale)")
        for (index, mask) in masks.enumerated() {
            print("Mask \(index): center=\(mask.center), size=\(mask.size), emoji=\(mask.emoji)")
        }
        print("==================")
    }
}

