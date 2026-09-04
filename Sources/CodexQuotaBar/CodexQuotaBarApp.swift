import SwiftUI

@main
struct CodexQuotaBarApp: App {
    @StateObject private var store = UsageStore()
    @AppStorage("toppingStyle") private var toppingStyleRaw = ToppingStyle.sprinkles.rawValue

    private var toppingStyle: ToppingStyle {
        ToppingStyle(rawValue: toppingStyleRaw) ?? .sprinkles
    }

    var body: some Scene {
        MenuBarExtra {
            QuotaPopover(
                snapshot: store.snapshot,
                status: store.status,
                toppingStyle: Binding(
                    get: { toppingStyle },
                    set: { toppingStyleRaw = $0.rawValue }
                ),
                refresh: {
                    Task { await store.refresh() }
                }
            )
        } label: {
            MenuBarStatusLabel(snapshot: store.snapshot, toppingStyle: toppingStyle)
        }
        .menuBarExtraStyle(.window)
    }
}
