import Combine
import Foundation

enum UsageStatus: Equatable {
    case loading
    case ready(source: String)
    case fallback(message: String)
    case failed(message: String)
}

@MainActor
final class UsageStore: ObservableObject {
    @Published private(set) var snapshot = UsageSnapshot.placeholder
    @Published private(set) var status: UsageStatus = .loading

    private let decoder = UsageStore.makeDecoder()
    private let usageClient = CodexUsageClient()
    private let refreshInterval: Duration = .seconds(60)
    private var refreshTask: Task<Void, Never>?

    init() {
        refreshTask = Task { [weak self] in
            guard let self else { return }
            await self.refreshLoop()
        }
    }

    deinit {
        refreshTask?.cancel()
    }

    private func refreshLoop() async {
        await refresh()

        while !Task.isCancelled {
            try? await Task.sleep(for: refreshInterval)
            await refresh()
        }
    }

    func refresh() async {
        status = .loading

        do {
            snapshot = try await usageClient.fetch()
            status = .ready(source: "Codex usage")
            return
        } catch {
            status = .fallback(message: syncFailureMessage(from: error))
        }

        do {
            let data = try Data(contentsOf: usageFileURL)
            snapshot = try decoder.decode(UsageSnapshot.self, from: data)
            status = .ready(source: usageFileURL.path)
        } catch {
            loadSampleKeepingCurrentStatus()
        }
    }

    private func loadSampleKeepingCurrentStatus() {
        snapshot = .placeholder
    }

    private var usageFileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appending(path: "CodexQuotaBar/usage.json")
    }

    private func syncFailureMessage(from error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }

        return error.localizedDescription
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
