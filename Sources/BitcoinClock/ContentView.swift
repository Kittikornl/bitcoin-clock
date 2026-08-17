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

    private var blocksUntilHalving: Int? {
        guard let height = service.blockHeight else { return nil }
        let nextHalvingBlock = ((height / Self.halvingInterval) + 1) * Self.halvingInterval
        return nextHalvingBlock - height
    }

    private var halvingBlockText: String {
        guard let height = service.blockHeight else { return "--" }
        let nextHalvingBlock = ((height / Self.halvingInterval) + 1) * Self.halvingInterval
        return nextHalvingBlock.formatted(.number.grouping(.automatic))
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

    private var lastHalvingBlock: Int? {
        guard let height = service.blockHeight else { return nil }
        return (height / Self.halvingInterval) * Self.halvingInterval
    }

    // Actual calendar dates of past halvings. Community counts cycle position in
    // days-since-halving (historical ATHs: 368 / 525 / 549 days), not block-quartile years.
    private static let halvingDates: [Int: Date] = {
        let cal = Calendar(identifier: .gregorian)
        func d(_ y: Int, _ m: Int, _ day: Int) -> Date {
            cal.date(from: DateComponents(year: y, month: m, day: day))!
        }
        return [
            630_000: d(2020, 5, 11),
            840_000: d(2024, 4, 20),
        ]
    }()

    private static let nominalCycleDays = 1460 // ~4 years

    private var daysSinceHalving: Int? {
        guard let height = service.blockHeight, let halvingBlock = lastHalvingBlock else { return nil }
        if let knownDate = Self.halvingDates[halvingBlock] {
            return Calendar.current.dateComponents([.day], from: knownDate, to: Date()).day
        }
        // no known date for this epoch (future halving) — estimate from block pace
        let blocksSince = height - halvingBlock
        return Int(Double(blocksSince) * Self.avgBlockSeconds / 86_400)
    }

    private var cycleProgress: Double? {
        guard let days = daysSinceHalving else { return nil }
        return Double(days) / Double(Self.nominalCycleDays)
    }

    // Bands fit to actual peak/bottom day-counts across all 3 completed cycles:
    //   cycle1 peak 27.8%, bottom 58.9% | cycle2 peak 37.5%, bottom 63.4% | cycle3 peak 38.1%, bottom 64.2%
    // -> peak clusters ~35%, bottom clusters ~62%. Small buffer zones around each point.
    private var cyclePhaseLabel: String {
        guard let progress = cycleProgress else { return "--" }
        switch progress {
        case ..<0.15: return "Post-Halving / Accumulation"
        case ..<0.33: return "Bull Run"
        case ..<0.43: return "Distribution / Peak Zone"
        case ..<0.64: return "Bear / Decline"
        default: return "Re-Accumulation / Bottom"
        }
    }

    private var cycleProgressText: String {
        guard let days = daysSinceHalving, let progress = cycleProgress else { return "--" }
        return "Day \(days) of ~\(Self.nominalCycleDays) — \(Int(progress * 100))%"
    }

    // (upper bound of current band, phase that starts once crossed) — mirrors cyclePhaseLabel bands.
    private static let phaseBoundaries: [(threshold: Double, nextPhase: String)] = [
        (0.15, "Bull Run"),
        (0.33, "Distribution / Peak Zone"),
        (0.43, "Bear / Decline"),
        (0.64, "Re-Accumulation / Bottom"),
    ]

    private var nextPhaseText: String {
        guard let days = daysSinceHalving, let progress = cycleProgress else { return "--" }
        guard let next = Self.phaseBoundaries.first(where: { progress < $0.threshold }) else {
            return "next: new cycle (see halving countdown above)"
        }
        let targetDay = Int(next.threshold * Double(Self.nominalCycleDays))
        let daysLeft = max(0, targetDay - days)
        return "next: \(next.nextPhase) in ~\(daysLeft)d"
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                Text("BITCOIN CLOCK")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.bitcoinOrange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("PRICE")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(priceText)
                        .font(.system(.title, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundStyle(.bitcoinOrange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("BLOCK HEIGHT")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(blockText)
                        .font(.system(.title, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundStyle(.bitcoinOrange)
                }

                VStack(alignment: .leading, spacing: 2) {
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

                VStack(alignment: .leading, spacing: 4) {
                    Text("4-YEAR CYCLE")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(cyclePhaseLabel)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundStyle(.bitcoinOrange)
                    Text(cycleProgressText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(nextPhaseText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if let progress = cycleProgress {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.gray.opacity(0.3))
                                Capsule().fill(Color.bitcoinOrange)
                                    .frame(width: geo.size.width * CGFloat(min(max(progress, 0), 1)))
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 20)
            .frame(width: 260)

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
            .padding(8)
        }
        .background(Color.black)
    }
}
