import UIKit

/// Draws the picture shown in the chat bubble: a Calendar-style date tile
/// on the app's gradient, with the event name and the leading time.
enum CardRenderer {
    static let top = UIColor(red: 0.20, green: 0.78, blue: 0.55, alpha: 1)
    static let bottom = UIColor(red: 0.10, green: 0.45, blue: 0.95, alpha: 1)

    static func image(for poll: Poll) -> UIImage {
        let size = CGSize(width: 600, height: 300)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let cg = ctx.cgContext

            // Background
            let colors = [top.cgColor, bottom.cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                cg.drawLinearGradient(gradient, start: .zero,
                                      end: CGPoint(x: size.width, y: size.height), options: [])
            }

            // Calendar tile
            let tile = CGRect(x: 36, y: 66, width: 168, height: 168)
            cg.saveGState()
            cg.setShadow(offset: CGSize(width: 0, height: 6), blur: 18,
                         color: UIColor.black.withAlphaComponent(0.18).cgColor)
            UIColor.white.setFill()
            UIBezierPath(roundedRect: tile, cornerRadius: 38).fill()
            cg.restoreGState()

            let date = poll.featuredDate ?? Date()
            let centered = NSMutableParagraphStyle()
            centered.alignment = .center
            let weekday = date.formatted(.dateTime.weekday(.abbreviated)).uppercased()
            let day = date.formatted(.dateTime.day())
            (weekday as NSString).draw(
                in: CGRect(x: tile.minX, y: tile.minY + 20, width: tile.width, height: 34),
                withAttributes: [.font: UIFont.systemFont(ofSize: 28, weight: .semibold),
                                 .foregroundColor: UIColor.systemRed,
                                 .paragraphStyle: centered])
            (day as NSString).draw(
                in: CGRect(x: tile.minX, y: tile.minY + 52, width: tile.width, height: 100),
                withAttributes: [.font: UIFont.systemFont(ofSize: 84, weight: .regular),
                                 .foregroundColor: UIColor.black,
                                 .paragraphStyle: centered])

            // Text
            let truncate = NSMutableParagraphStyle()
            truncate.lineBreakMode = .byTruncatingTail
            let textX: CGFloat = 232
            let textW = size.width - textX - 32

            func draw(_ text: String, y: CGFloat, height: CGFloat, size: CGFloat, weight: UIFont.Weight, alpha: CGFloat) {
                (text as NSString).draw(
                    in: CGRect(x: textX, y: y, width: textW, height: height),
                    withAttributes: [.font: UIFont.systemFont(ofSize: size, weight: weight),
                                     .foregroundColor: UIColor.white.withAlphaComponent(alpha),
                                     .paragraphStyle: truncate])
            }

            draw(poll.title, y: 78, height: 50, size: 40, weight: .bold, alpha: 1)

            if let best = poll.bestSlots.first {
                draw("★ " + Formatters.timeRange(start: poll.slots[best], minutes: poll.durationMinutes),
                     y: 136, height: 40, size: 30, weight: .semibold, alpha: 0.95)
                draw("\(poll.count(for: best)) of \(poll.respondentCount) can make it",
                     y: 182, height: 36, size: 26, weight: .regular, alpha: 0.85)
            } else {
                draw(poll.slots.count == 1 ? "1 time to choose from" : "\(poll.slots.count) times to choose from",
                     y: 136, height: 40, size: 30, weight: .semibold, alpha: 0.95)
                draw("Tap to share when you're free", y: 182, height: 36, size: 26, weight: .regular, alpha: 0.85)
            }
        }
    }
}
