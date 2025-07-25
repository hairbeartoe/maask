import SwiftUI

// View for a single draggable, resizable, tappable emoji overlay
struct EmojiOverlayView: View {
    @Binding var mask: EmojiMask
    let imageSize: CGSize
    let displaySize: CGSize
    let onRemove: () -> Void

    @State private var dragOffset = CGSize.zero
    @State private var lastDragPosition: CGPoint?
    @State private var scale: CGFloat = 1.0

    // Helper to map image coordinates to display coordinates
    func imageToDisplay(_ point: CGPoint) -> CGPoint {
        let scale = min(displaySize.width / imageSize.width, displaySize.height / imageSize.height)
        let xOffset = (displaySize.width - imageSize.width * scale) / 2
        let yOffset = (displaySize.height - imageSize.height * scale) / 2
        return CGPoint(
            x: point.x * scale + xOffset,
            y: point.y * scale + yOffset
        )
    }

    // Helper to map display coordinates back to image coordinates
    func displayToImage(_ point: CGPoint) -> CGPoint {
        let scale = min(displaySize.width / imageSize.width, displaySize.height / imageSize.height)
        let xOffset = (displaySize.width - imageSize.width * scale) / 2
        let yOffset = (displaySize.height - imageSize.height * scale) / 2
        return CGPoint(
            x: (point.x - xOffset) / scale,
            y: (point.y - yOffset) / scale
        )
    }

    var body: some View {
        // The emoji overlays
        Text(mask.emoji)
            .font(.system(size: mask.size * scale))
            .position(imageToDisplay(CGPoint(x: mask.center.x + dragOffset.width, y: mask.center.y + dragOffset.height)))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        mask.center.x += value.translation.width
                        mask.center.y += value.translation.height
                        dragOffset = .zero
                    }
            )
            .gesture(
                TapGesture()
                    .onEnded {
                        // Cycle emoji
                        mask.emojiIndex = (mask.emojiIndex + 1) % EmojiMask.emojiOptions.count
                    }
            )
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = value
                    }
                    .onEnded { value in
                        mask.size *= value
                        scale = 1.0
                    }
            )
            .gesture(
                TapGesture(count: 2)
                    .onEnded {
                        // Double-tap to remove
                        onRemove()
                    }
            )
    }
}
