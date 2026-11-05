import UIKit

/// Draws the picture shown in the chat bubble.
enum CardRenderer {
    static let top = UIColor(red: 0.20, green: 0.78, blue: 0.55, alpha: 1)
    static let bottom = UIColor(red: 0.10, green: 0.45, blue: 0.95, alpha: 1)

    static func image(for poll: Poll) -> UIImage {
        let size = CGSize(width: 600, height: 300)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let cg = ctx.cgContext
            let colors = [top.cgColor, bottom.cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                cg.drawLinearGradient(gradient, start: .zero,
                                      end: CGPoint(x: size.width, y: size.height), options: [])
            }

            let symbol = UIImage(systemName: "calendar.badge.clock",
                                 withConfiguration: UIImage.SymbolConfiguration(pointSize: 46, weight: .bold))
            symbol?.withTintColor(.white, renderingMode: .alwaysOriginal).draw(at: CGPoint(x: 36, y: 30))

            let truncate = NSMutableParagraphStyle()
            truncate.lineBreakMode = .byTruncatingTail

            func draw(_ text: String, y: CGFloat, height: CGFloat, size: CGFloat, weight: UIFont.Weight, alpha: CGFloat) {
                (text as NSString).draw(
                    in: CGRect(x: 36, y: y, width: 528, height: height),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: size, weight: weight),
                        .foregroundColor: UIColor.white.withAlphaComponent(alpha),
                        .paragraphStyle: truncate,
                    ])
            }

            draw(poll.title, y: 108, height: 58, size: 46, weight: .heavy, alpha: 1)

            if let best = poll.bestSlots.first {
                draw("⭐️ " + poll.timeText(for: best), y: 176, height: 40, size: 30, weight: .semibold, alpha: 0.95)
                draw("\(poll.count(for: best)) of \(poll.respondentCount) can make it",
                     y: 226, height: 36, size: 26, weight: .medium, alpha: 0.85)
            } else {
                draw("When are you free?", y: 176, height: 40, size: 30, weight: .semibold, alpha: 0.95)
                draw("\(poll.slots.count) time options · tap to vote",
                     y: 226, height: 36, size: 26, weight: .medium, alpha: 0.85)
            }
        }
    }
}
