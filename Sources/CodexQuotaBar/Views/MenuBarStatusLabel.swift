import AppKit
import SwiftUI

struct MenuBarStatusLabel: View {
    let snapshot: UsageSnapshot
    let toppingStyle: ToppingStyle

    var body: some View {
        HStack(spacing: 5) {
            MenuBarCookieGlyph(usedPercent: snapshot.weeklyWindow.usedPercent)

            Text("\(snapshot.weeklyWindow.remainingPercent)%")
                .font(.system(size: 12, weight: .semibold))
                .monospacedDigit()
        }
    }
}

private struct MenuBarCookieGlyph: View {
    let usedPercent: Int

    var body: some View {
        Image(nsImage: MenuBarCookieImage.make(usedPercent: usedPercent))
            .resizable()
            .scaledToFit()
            .frame(width: 14, height: 14)
            .accessibilityHidden(true)
    }
}

private enum MenuBarCookieImage {
    static func make(usedPercent: Int) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()

        NSColor.black.setFill()
        path(in: CGRect(origin: .zero, size: size), usedPercent: usedPercent).fill()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }

    private static func path(in rect: CGRect, usedPercent: Int) -> NSBezierPath {
        let visibleUsedPercent = usedPercent > 0 ? max(usedPercent, 20) : usedPercent
        let biteProgress = min(1, max(0, CGFloat(visibleUsedPercent) / 100))
        let path = NSBezierPath()

        guard biteProgress > 0 else {
            path.appendOval(in: rect.insetBy(dx: rect.width * 0.10, dy: rect.height * 0.10))
            return path
        }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.40
        let biteAngle = max(.pi * 0.42, .pi * 1.55 * biteProgress)
        let start = -biteAngle / 2
        let end = biteAngle / 2
        let endEdge = point(center: center, radius: radius, angle: end)

        path.move(to: endEdge)
        path.appendArc(
            withCenter: center,
            radius: radius,
            startAngle: degrees(end),
            endAngle: degrees(start + .pi * 2),
            clockwise: false
        )
        path.line(to: point(center: center, radius: radius * 0.36, angle: start * 0.26))
        path.line(to: point(center: center, radius: radius * 0.38, angle: end * 0.24))
        path.close()

        return path
    }

    private static func point(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
    }

    private static func degrees(_ radians: CGFloat) -> CGFloat {
        radians * 180 / .pi
    }
}
