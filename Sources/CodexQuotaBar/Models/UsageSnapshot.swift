import Foundation

struct UsageSnapshot: Codable, Equatable {
    var weeklyWindow: QuotaWindow
    var shortWindow: QuotaWindow?
    var tokensUsed: Int?
    var updatedAt: Date

    var usedPercent: Int {
        weeklyWindow.usedPercent
    }

    var resetAt: Date {
        weeklyWindow.resetAt
    }

    var windowMinutes: Int {
        weeklyWindow.windowMinutes
    }

    var remainingPercent: Int {
        weeklyWindow.remainingPercent
    }

    static var placeholder: UsageSnapshot {
        UsageSnapshot(
            weeklyWindow: QuotaWindow(
                usedPercent: 49,
                resetAt: Date(timeIntervalSince1970: 1_791_092_693),
                windowMinutes: 10_080
            ),
            shortWindow: QuotaWindow(
                usedPercent: 18,
                resetAt: Date(timeIntervalSinceNow: 9_800),
                windowMinutes: 300
            ),
            tokensUsed: 128_400,
            updatedAt: .now
        )
    }
}

struct QuotaWindow: Codable, Equatable {
    var usedPercent: Int
    var resetAt: Date
    var windowMinutes: Int

    var remainingPercent: Int {
        max(0, min(100, 100 - usedPercent))
    }
}
