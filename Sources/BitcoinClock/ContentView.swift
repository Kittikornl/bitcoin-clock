import SwiftUI

extension Color {
    static let bitcoinOrange = Color(
        red: BitcoinPalette.orangeR,
        green: BitcoinPalette.orangeG,
        blue: BitcoinPalette.orangeB
    )
}

extension ShapeStyle where Self == Color {
    static var bitcoinOrange: Color { Color.bitcoinOrange }
}

struct ContentView: View {
    @ObservedObject var service: BitcoinService

    private var priceText: String {
        guard let price = service.priceUSD else { return "--" }
        return price.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    private var blockText: String {
        guard let height = service.blockHeight else { return "--" }
        return height.formatted(.number.grouping(.automatic))
    }

    private static let halvingInterval = 210_000
    private static let avgBlockSeconds: TimeInterval = 600 // 10 min

    private var nextHalvingBlock: Int? {
        guard let height = service.blockHeight else { return nil }
        return ((height / Self.halvingInterval) + 1) * Self.halvingInterval
    }

    private var blocksUntilHalving: Int? {
        guard let height = service.blockHeight, let next = nextHalvingBlock else { return nil }
        return next - height
    }

    private var halvingBlockText: String {
        guard let next = nextHalvingBlock else { return "--" }
        return next.formatted(.number.grouping(.automatic))
    }

    private var halvingETAText: String {
        guard let blocksLeft = blocksUntilHalving else { return "--" }
        let seconds = TimeInterval(blocksLeft) * Self.avgBlockSeconds
        let eta = Date().addingTimeInterval(seconds)
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour]
        formatter.unitsStyle = .abbreviated
        let remaining = formatter.string(from: seconds) ?? "--"
        return "~\(remaining) (\(eta.formatted(date: .abbreviated, time: .omitted)))"
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 18) {
                Text("BITCOIN CLOCK")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.bitcoinOrange)
                    .padding(.trailing, 16)

                VStack(alignment: .leading, spacing: 4) {
                    Text("PRICE")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(priceText)
                        .font(.system(.title, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundStyle(.bitcoinOrange)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("BLOCK HEIGHT")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(blockText)
                        .font(.system(.title, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundStyle(.bitcoinOrange)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("NEXT HALVING — BLOCK \(halvingBlockText)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(halvingETAText)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundStyle(.bitcoinOrange)
                    if let blocksLeft = blocksUntilHalving {
                        Text("\(blocksLeft.formatted()) blocks left")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 20)
            .padding(.bottom, 24)
            .frame(width: 240)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q")
            .padding(10)
        }
        .background(Color.black)
    }
}
