import SwiftUI

// Model representing an emoji overlay on a face
struct EmojiMask: Identifiable {
    let id = UUID()
    var center: CGPoint // Center position in image coordinates
    var size: CGFloat   // Size (width/height) of the emoji
    var emojiIndex: Int // Index in the emoji list
    static let emojiOptions = ["😊", "🐵", "😎", "🦄", "🤖"]
    var emoji: String { EmojiMask.emojiOptions[emojiIndex] }
} 