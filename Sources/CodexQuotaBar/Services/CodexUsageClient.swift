import Foundation

enum CodexUsageClientError: Error, LocalizedError {
    case signedOut(String)
    case unavailable(String)

    var errorDescription: String? {
        switch self {
        case .signedOut(let message), .unavailable(let message):
            return message
        }
    }
}

struct CodexUsageClient {
    func fetch() async throws -> UsageSnapshot {
        let auth = try loadAuth()
        var request = URLRequest(url: URL(string: "https://chatgpt.com/backend-api/wham/usage")!)
        request.setValue("Bearer \(auth.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Codex Desktop", forHTTPHeaderField: "originator")
        request.setValue("CODEX", forHTTPHeaderField: "OAI-Product-Sku")

        if let accountID = auth.accountID {
            request.setValue(accountID, forHTTPHeaderField: "ChatGPT-Account-Id")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CodexUsageClientError.unavailable("Quota service did not return HTTP.")
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return try parseUsage(data)
        case 401, 403:
            throw CodexUsageClientError.signedOut("Codex login expired. Please sign in again.")
        case 429:
            throw CodexUsageClientError.unavailable("Quota service is rate limited. It will retry automatically.")
        default:
            throw CodexUsageClientError.unavailable("Quota service is temporarily unavailable.")
        }
    }
}

private struct CodexAuth {
    let accessToken: String
    let accountID: String?
}

private func loadAuth() throws -> CodexAuth {
    let authURL = authFileURL()
    let data: Data

    do {
        data = try Data(contentsOf: authURL)
    } catch {
        throw CodexUsageClientError.signedOut("Please sign in to Codex Desktop first.")
    }

    guard data.count <= 256 * 1024 else {
        throw CodexUsageClientError.signedOut("Codex login data is unavailable.")
    }

    let json = try jsonObject(from: data)
    let tokens = dictionary(json["tokens"]) ?? json

    guard let accessToken = string(tokens["access_token"]) ?? string(tokens["accessToken"]) else {
        throw CodexUsageClientError.signedOut("Codex login expired. Please sign in again.")
    }

    let accountID = string(tokens["account_id"])
        ?? string(tokens["accountId"])
        ?? accountIDFromJWT(accessToken)

    return CodexAuth(accessToken: accessToken, accountID: accountID)
}

private func authFileURL() -> URL {
    if let codexHome = ProcessInfo.processInfo.environment["CODEX_HOME"], !codexHome.isEmpty {
        return URL(fileURLWithPath: codexHome).appending(path: "auth.json")
    }

    return FileManager.default.homeDirectoryForCurrentUser
        .appending(path: ".codex/auth.json")
}

private func parseUsage(_ data: Data) throws -> UsageSnapshot {
    guard data.count <= 1024 * 1024 else {
        throw CodexUsageClientError.unavailable("Quota response is too large.")
    }

    let root = try jsonObject(from: data)
    let rateLimit = dictionary(root["rate_limit"])
        ?? dictionary(root["rateLimit"])
        ?? root

    let shortWindow = findWindow(in: rateLimit, names: ["primary_window", "primaryWindow", "short_window", "shortWindow", "five_hour_window", "fiveHourWindow", "5h", "primary"], expectedSeconds: 18_000)
    let weeklyWindow = findWindow(in: rateLimit, names: ["secondary_window", "secondaryWindow", "weekly_window", "weeklyWindow", "week_window", "weekWindow", "weekly", "secondary", "primary_window", "primaryWindow", "primary"], expectedSeconds: 604_800)

    guard let displayWindow = weeklyWindow ?? shortWindow else {
        throw CodexUsageClientError.unavailable("Quota response does not contain a recognized usage window.")
    }

    return UsageSnapshot(
        weeklyWindow: displayWindow.quotaWindow,
        shortWindow: shortWindow?.quotaWindow,
        tokensUsed: nil,
        updatedAt: .now
    )
}

private struct ParsedWindow {
    let remainingPercent: Double
    let resetsAt: Date?
    let windowSeconds: Int

    var quotaWindow: QuotaWindow {
        QuotaWindow(
            usedPercent: Int((100 - remainingPercent).rounded()),
            resetAt: resetsAt ?? .now,
            windowMinutes: max(0, windowSeconds / 60)
        )
    }
}

private func findWindow(in rateLimit: [String: Any], names: [String], expectedSeconds: Int) -> ParsedWindow? {
    for name in names {
        guard let value = dictionary(rateLimit[name]), let window = parseWindow(value) else {
            continue
        }

        if window.windowSeconds == 0 || abs(window.windowSeconds - expectedSeconds) <= 60 {
            return window
        }
    }

    for key in ["windows", "limit_windows", "limitWindows", "limits", "buckets"] {
        guard let items = rateLimit[key] as? [[String: Any]] else {
            continue
        }

        for item in items {
            guard let window = parseWindow(item) else {
                continue
            }

            let durationMatches = expectedSeconds > 0 && abs(window.windowSeconds - expectedSeconds) <= 60
            let nameMatches = string(item["name"])
                .or(string(item["type"]))
                .or(string(item["id"]))
                .or(string(item["window"]))
                .or(string(item["label"]))
                .map { label in
                    let lower = label.lowercased()
                    return names.contains { lower == $0.lowercased() || lower.contains($0.lowercased()) }
                } ?? false

            if durationMatches || nameMatches {
                return window
            }
        }
    }

    return nil
}

private func parseWindow(_ value: [String: Any]) -> ParsedWindow? {
    let remainingPercent: Double

    if let remaining = number(value, keys: ["remaining_percent", "remainingPercent", "remaining_pct", "remainingPct", "remaining_ratio", "remainingRatio", "remaining"]) {
        remainingPercent = scaleIfRatio(remaining.key, remaining.value)
    } else if let used = number(value, keys: ["used_percent", "usedPercent", "used_pct", "usedPct", "used_ratio", "usedRatio", "utilization", "used"]) {
        remainingPercent = 100 - scaleIfRatio(used.key, used.value)
    } else {
        return nil
    }

    return ParsedWindow(
        remainingPercent: min(100, max(0, remainingPercent)),
        resetsAt: timestamp(value, keys: ["reset_at", "resetAt", "resets_at", "resetsAt", "reset_time", "resetTime"]),
        windowSeconds: integer(value, keys: ["limit_window_seconds", "limitWindowSeconds", "window_seconds", "windowSeconds", "duration_seconds", "durationSeconds", "period_seconds", "periodSeconds"]) ?? 0
    )
}

private func scaleIfRatio(_ key: String, _ value: Double) -> Double {
    let lower = key.lowercased()
    if lower.contains("ratio") || lower == "utilization" || (!lower.contains("percent") && !lower.contains("pct") && value <= 1) {
        return value * 100
    }

    return value
}

private func jsonObject(from data: Data) throws -> [String: Any] {
    guard let value = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        throw CodexUsageClientError.unavailable("Quota response format has changed.")
    }

    return value
}

private func dictionary(_ value: Any?) -> [String: Any]? {
    value as? [String: Any]
}

private func string(_ value: Any?) -> String? {
    value as? String
}

private func integer(_ value: [String: Any], keys: [String]) -> Int? {
    for key in keys {
        if let item = value[key] as? Int {
            return item
        }

        if let item = value[key] as? Double {
            return Int(item)
        }
    }

    return nil
}

private func number(_ value: [String: Any], keys: [String]) -> (key: String, value: Double)? {
    for key in keys {
        if let item = value[key] as? Double {
            return (key, item)
        }

        if let item = value[key] as? Int {
            return (key, Double(item))
        }
    }

    return nil
}

private func timestamp(_ value: [String: Any], keys: [String]) -> Date? {
    for key in keys {
        if let seconds = value[key] as? Int {
            return Date(timeIntervalSince1970: TimeInterval(seconds))
        }

        if let seconds = value[key] as? Double {
            return Date(timeIntervalSince1970: seconds)
        }

        if let text = value[key] as? String {
            return ISO8601DateFormatter().date(from: text)
        }
    }

    return nil
}

private func accountIDFromJWT(_ token: String) -> String? {
    let parts = token.split(separator: ".")
    guard parts.count > 1 else { return nil }

    var payload = String(parts[1])
    payload = payload.replacingOccurrences(of: "-", with: "+")
    payload = payload.replacingOccurrences(of: "_", with: "/")
    payload.append(String(repeating: "=", count: (4 - payload.count % 4) % 4))

    guard let data = Data(base64Encoded: payload),
          let json = try? jsonObject(from: data) else {
        return nil
    }

    return string(json["https://api.openai.com/auth.chatgpt_account_id"])
        ?? string(json["chatgpt_account_id"])
}

private extension Optional {
    func or(_ other: Optional) -> Optional {
        self ?? other
    }
}
