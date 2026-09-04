import SwiftUI

struct CookieView: View {
    let usedPercent: Int
    let topping: ToppingStyle
    var size: CGFloat
    var showsShadow = true
    var minimumVisibleBitePercent = 0

    var body: some View {
        ZStack {
            cookieBase

            if size > 28 {
                crumbLayer
                    .mask(cookieMask)

                toppingLayer
                    .mask(cookieMask)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: showsShadow ? .black.opacity(0.16) : .clear, radius: size * 0.08, y: size * 0.04)
        .accessibilityLabel("Cookie quota")
        .accessibilityValue("\(100 - usedPercent)% remaining")
    }

    private var cookieBase: some View {
        cookieShape
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.74, blue: 0.39),
                        Color(red: 0.74, green: 0.39, blue: 0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                style: FillStyle(eoFill: false)
            )
            .overlay {
                cookieShape
                    .stroke(Color(red: 0.36, green: 0.19, blue: 0.08).opacity(size <= 28 ? 0.42 : 0.24), lineWidth: max(1, size * 0.025))
            }
            .overlay {
                cookieShape
                    .stroke(.white.opacity(0.16), lineWidth: max(1, size * 0.018))
                    .blur(radius: size * 0.012)
                    .offset(x: -size * 0.012, y: -size * 0.012)
            }
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(.white.opacity(0.18))
                    .frame(width: size * 0.48, height: size * 0.28)
                    .blur(radius: size * 0.075)
                    .offset(x: size * 0.12, y: size * 0.10)
            }
            .mask(cookieMask)
    }

    private var crumbLayer: some View {
        ZStack {
            ForEach(crumbMarks) { mark in
                Circle()
                    .fill(mark.color.opacity(0.24))
                    .frame(width: size * mark.scale, height: size * mark.scale)
                    .position(x: mark.x * size, y: mark.y * size)
            }
        }
    }

    private var toppingLayer: some View {
        ZStack {
            ForEach(toppingMarks) { mark in
                toppingMark(mark)
                    .position(x: mark.x * size, y: mark.y * size)
                    .rotationEffect(.degrees(mark.rotation))
            }
        }
    }

    @ViewBuilder
    private func toppingMark(_ mark: ToppingMark) -> some View {
        switch topping {
        case .sprinkles:
            Capsule()
                .fill(mark.color)
                .frame(width: size * 0.12, height: size * 0.032)
        case .chocolate:
            Circle()
                .fill(Color(red: 0.24, green: 0.11, blue: 0.06))
                .frame(width: size * mark.scale, height: size * mark.scale)
                .overlay {
                    Circle()
                        .fill(.white.opacity(0.10))
                        .frame(width: size * mark.scale * 0.42)
                        .offset(x: -size * mark.scale * 0.12, y: -size * mark.scale * 0.12)
                }
        case .cream:
            CreamDrop()
                .fill(Color(red: 1.0, green: 0.94, blue: 0.84))
                .frame(width: size * mark.scale * 1.35, height: size * mark.scale * 1.15)
                .shadow(color: .black.opacity(0.08), radius: size * 0.01, y: size * 0.008)
        }
    }

    private var cookieShape: CookieBiteShape {
        CookieBiteShape(
            usedPercent: usedPercent,
            minimumVisibleBitePercent: minimumVisibleBitePercent
        )
    }

    private var cookieMask: some View {
        cookieShape.fill(style: FillStyle(eoFill: false))
    }

    private var toppingMarks: [ToppingMark] {
        [
            ToppingMark(id: 0, x: 0.28, y: 0.27, rotation: 18, scale: 0.070, color: .pink),
            ToppingMark(id: 1, x: 0.52, y: 0.22, rotation: -28, scale: 0.064, color: .cyan),
            ToppingMark(id: 2, x: 0.60, y: 0.41, rotation: 34, scale: 0.076, color: .yellow),
            ToppingMark(id: 3, x: 0.36, y: 0.54, rotation: -12, scale: 0.070, color: .mint),
            ToppingMark(id: 4, x: 0.55, y: 0.66, rotation: 9, scale: 0.080, color: .orange),
            ToppingMark(id: 5, x: 0.24, y: 0.70, rotation: -42, scale: 0.064, color: .purple),
            ToppingMark(id: 6, x: 0.46, y: 0.38, rotation: 51, scale: 0.068, color: .blue)
        ]
    }

    private var crumbMarks: [CookieCrumbMark] {
        [
            CookieCrumbMark(id: 0, x: 0.22, y: 0.42, scale: 0.050, color: Color(red: 0.42, green: 0.21, blue: 0.08)),
            CookieCrumbMark(id: 1, x: 0.35, y: 0.31, scale: 0.028, color: Color(red: 1.0, green: 0.82, blue: 0.48)),
            CookieCrumbMark(id: 2, x: 0.43, y: 0.72, scale: 0.038, color: Color(red: 0.52, green: 0.27, blue: 0.10)),
            CookieCrumbMark(id: 3, x: 0.57, y: 0.52, scale: 0.032, color: Color(red: 1.0, green: 0.82, blue: 0.48)),
            CookieCrumbMark(id: 4, x: 0.31, y: 0.61, scale: 0.026, color: Color(red: 0.38, green: 0.18, blue: 0.07)),
            CookieCrumbMark(id: 5, x: 0.63, y: 0.29, scale: 0.030, color: Color(red: 0.50, green: 0.25, blue: 0.09))
        ]
    }
}

struct CookieBiteShape: Shape {
    let usedPercent: Int
    var minimumVisibleBitePercent = 0

    func path(in rect: CGRect) -> Path {
        let visibleUsedPercent = usedPercent > 0 ? max(usedPercent, minimumVisibleBitePercent) : usedPercent
        let biteProgress = min(1, max(0, CGFloat(visibleUsedPercent) / 100))

        var path = Path()
        guard biteProgress > 0 else {
            path.addEllipse(in: rect.insetBy(dx: rect.width * 0.04, dy: rect.height * 0.04))
            return path
        }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.46
        let biteAngle = max(.pi * 0.30, .pi * 1.55 * biteProgress)
        let start = -biteAngle / 2
        let end = biteAngle / 2
        let endEdge = point(center: center, radius: radius, angle: end)

        path.move(to: endEdge)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .radians(end),
            endAngle: .radians(start + .pi * 2),
            clockwise: false
        )

        let apex = CGPoint(x: center.x + radius * 0.08, y: center.y)
        addWavyLine(
            to: &path,
            from: point(center: center, radius: radius, angle: start),
            to: CGPoint(x: apex.x - radius * 0.03, y: apex.y - radius * 0.02),
            amplitude: radius * 0.026
        )
        addWavyLine(
            to: &path,
            from: CGPoint(x: apex.x + radius * 0.03, y: apex.y + radius * 0.02),
            to: endEdge,
            amplitude: radius * 0.026
        )
        path.closeSubpath()

        return path
    }

    private func point(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
    }

    private func addWavyLine(to path: inout Path, from start: CGPoint, to end: CGPoint, amplitude: CGFloat) {
        let steps = 6
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = max(1, sqrt(dx * dx + dy * dy))
        let normal = CGPoint(x: -dy / length, y: dx / length)

        for index in 1...steps {
            let fraction = CGFloat(index) / CGFloat(steps)
            let direction: CGFloat = index.isMultiple(of: 2) ? -1 : 1
            let fade = sin(.pi * fraction)
            path.addLine(to: CGPoint(
                x: start.x + dx * fraction + normal.x * amplitude * direction * fade,
                y: start.y + dy * fraction + normal.y * amplitude * direction * fade
            ))
        }
    }
}

private struct CreamDrop: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control1: CGPoint(x: rect.maxX, y: rect.minY),
            control2: CGPoint(x: rect.maxX, y: rect.midY * 0.65)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: rect.maxY * 0.82),
            control2: CGPoint(x: rect.maxX * 0.64, y: rect.maxY)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.midY),
            control1: CGPoint(x: rect.maxX * 0.34, y: rect.maxY),
            control2: CGPoint(x: rect.minX, y: rect.maxY * 0.82)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control1: CGPoint(x: rect.minX, y: rect.midY * 0.65),
            control2: CGPoint(x: rect.minX, y: rect.minY)
        )
        return path
    }
}

private struct ToppingMark: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let rotation: Double
    let scale: CGFloat
    let color: Color
}

private struct CookieCrumbMark: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let scale: CGFloat
    let color: Color
}
