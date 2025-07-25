import Vision
import UIKit
import ImageIO

// Detects faces in a UIImage and returns their bounding boxes (in image coordinates)
class FaceDetector {

    static func detectFaces(in image: UIImage, completion: @escaping ([CGRect]) -> Void) {
        guard let cgImage = image.cgImage else {
            print("No cgImage found in UIImage")
            completion([])
            return
        }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
                let results = (request.results as? [VNFaceObservation]) ?? []
                print("Vision results count:", results.count)
                let size = CGSize(width: cgImage.width, height: cgImage.height)
                let rects = results.map { obs in
                    let r = obs.boundingBox
                    return CGRect(
                        x: r.origin.x * size.width,
                        y: (1 - r.origin.y - r.size.height) * size.height,
                        width: r.size.width * size.width,
                        height: r.size.height * size.height
                    )
                }
                completion(rects)
            } catch {
                print("Vision error:", error)
                completion([])
            }
        }
    }
}

// Place this extension outside the class
extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
} 