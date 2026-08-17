import Foundation

@MainActor
final class BitcoinService: ObservableObject {
    @Published var priceUSD: Int?
    @Published var blockHeight: Int?
    @Published var lastUpdated: Date?

    private var priceTask: Task<Void, Never>?
    private var blockTask: Task<Void, Never>?
    private var started = false

    func start() {
        guard !started else { return }
        started = true
        priceTask = Task {
            while !Task.isCancelled {
                await refreshPrice()
                try? await Task.sleep(for: .seconds(15))
            }
        }
        blockTask = Task {
            while !Task.isCancelled {
                await refreshBlockHeight()
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }

    func stop() {
        priceTask?.cancel()
        blockTask?.cancel()
    }

    private func refreshPrice() async {
        guard let url = URL(string: "https://mempool.space/api/v1/prices") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(PriceResponse.self, from: data)
            priceUSD = decoded.USD
            lastUpdated = Date()
        } catch {
            // keep last-known value on failure
        }
    }

    private func refreshBlockHeight() async {
        guard let url = URL(string: "https://mempool.space/api/blocks/tip/height") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let height = Int(String(data: data, encoding: .utf8) ?? "") {
                blockHeight = height
                lastUpdated = Date()
            }
        } catch {
            // keep last-known value on failure
        }
    }
}

private struct PriceResponse: Decodable {
    let USD: Int
}
