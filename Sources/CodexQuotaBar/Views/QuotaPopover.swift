import AppKit
import SwiftUI

struct QuotaPopover: View {
    let snapshot: UsageSnapshot
    let status: UsageStatus
    @Binding var toppingStyle: ToppingStyle
    let refresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            header

            HStack(alignment: .center, spacing: 16) {
                CookieView(
                    usedPercent: snapshot.weeklyWindow.usedPercent,
                    topping: toppingStyle,
                    size: 92,
                    minimumVisibleBitePercent: 8
                )

                heroMetric
            }

            windowCards
            toppingPicker
            footer

            statusLine
        }
        .padding(14)
        .frame(width: 280)
        .background {
            LiquidGlassPanel(cornerRadius: 18)
        }
        .background {
            WindowGlassConfigurator()
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                Text("Codex")
                    .font(.system(size: 16, weight: .semibold))

                Circle()
                    .fill(statusColor)
                    .frame(width: 7, height: 7)

                Text(statusBadgeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var heroMetric: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(snapshot.weeklyWindow.remainingPercent)%")
                .font(.system(size: 30, weight: .bold))
                .monospacedDigit()

            Text("weekly cookie left")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(snapshot.weeklyWindow.usedPercent)% eaten")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary.opacity(0.72))
        }
    }

    private var windowCards: some View {
        HStack(spacing: 7) {
            windowCard(
                title: "5h window",
                window: snapshot.shortWindow,
                fallback: "Waiting"
            )

            windowCard(
                title: "Weekly",
                window: snapshot.weeklyWindow,
                fallback: "--"
            )
        }
    }

    private func windowCard(title: String, window: QuotaWindow?, fallback: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            if let window {
                Text("\(window.remainingPercent)% left")
                    .font(.system(size: 14, weight: .semibold))
                    .monospacedDigit()
            } else {
                Text(fallback)
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 9)
        .background(.quaternary.opacity(0.42), in: RoundedRectangle(cornerRadius: 10))
    }

    private var toppingPicker: some View {
        HStack(spacing: 6) {
            ForEach(ToppingStyle.allCases) { topping in
                Button {
                    toppingStyle = topping
                } label: {
                    HStack(spacing: 5) {
                        toppingPreview(topping)
                        Text(topping.title)
                            .font(.caption)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 7)
                    .frame(maxWidth: .infinity)
                    .background(topping == toppingStyle ? Color.accentColor.opacity(0.16) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                    .overlay {
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(topping == toppingStyle ? Color.accentColor.opacity(0.40) : Color.secondary.opacity(0.18), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .help(topping.title)
            }
        }
    }

    @ViewBuilder
    private func toppingPreview(_ topping: ToppingStyle) -> some View {
        switch topping {
        case .sprinkles:
            Image(systemName: "sparkles")
                .foregroundStyle(.pink)
        case .chocolate:
            Image(systemName: "circle.fill")
                .foregroundStyle(Color(red: 0.24, green: 0.11, blue: 0.06))
        case .cream:
            Image(systemName: "drop.fill")
                .foregroundStyle(Color(red: 0.92, green: 0.78, blue: 0.55))
        }
    }

    private var footer: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Resets")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text(resetText)
                    .font(.system(size: 13, weight: .medium))
            }

            Spacer()

            Button(action: refresh) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Refresh")

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .help("Quit")
        }
    }

    private var statusLine: some View {
        HStack(spacing: 6) {
            Image(systemName: statusIcon)
            Text(statusText)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var resetText: String {
        snapshot.weeklyWindow.resetAt.formatted(date: .abbreviated, time: .shortened)
    }

    private var statusText: String {
        switch status {
        case .loading:
            return "Loading usage data..."
        case .ready(let source):
            return source
        case .fallback(let message):
            return message
        case .failed(let message):
            return message
        }
    }

    private var statusIcon: String {
        switch status {
        case .loading:
            return "hourglass"
        case .ready:
            return "checkmark.circle"
        case .fallback:
            return "info.circle"
        case .failed:
            return "exclamationmark.triangle"
        }
    }

    private var statusBadgeText: String {
        switch status {
        case .loading:
            return "Syncing"
        case .ready:
            return "Synced"
        case .fallback, .failed:
            return "Offline"
        }
    }

    private var statusColor: Color {
        switch status {
        case .loading:
            return .orange
        case .ready:
            return .green
        case .fallback, .failed:
            return .red
        }
    }

}

private struct LiquidGlassPanel: View {
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.clear)
            .background {
                VisualEffectView(material: .popover, blendingMode: .behindWindow)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.16),
                                .white.opacity(0.04),
                                .black.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.plusLighter)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.white.opacity(0.28), lineWidth: 1)
            }
            .shadow(color: .white.opacity(0.08), radius: 8, x: -3, y: -3)
            .shadow(color: .black.opacity(0.16), radius: 18, x: 8, y: 10)
            .overlay(alignment: .topLeading) {
                Capsule()
                    .fill(.white.opacity(0.16))
                    .frame(width: 72, height: 1.5)
                    .blur(radius: 1.5)
                    .padding(.top, 8)
                    .padding(.leading, 18)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

private struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = .active
    }
}

private struct WindowGlassConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            configure(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configure(nsView.window)
        }
    }

    private func configure(_ window: NSWindow?) {
        window?.isOpaque = false
        window?.backgroundColor = .clear
        window?.hasShadow = true
    }
}
