import AppKit
import SwiftUI
import Combine
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let service = BitcoinService()
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var cancellables: Set<AnyCancellable> = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.action = #selector(togglePopover)
        statusItem.button?.target = self

        let hostingController = NSHostingController(rootView: ContentView(service: service))
        hostingController.sizingOptions = [.preferredContentSize]

        popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = hostingController

        service.start()
        updateTitle()

        service.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateTitle() }
            .store(in: &cancellables)

        DispatchQueue.main.async { [weak self] in
            self?.registerLaunchAtLogin()
        }
    }

    private func registerLaunchAtLogin() {
        guard SMAppService.mainApp.status != .enabled else { return }
        do {
            try SMAppService.mainApp.register()
        } catch {
            NSLog("Launch-at-login registration failed: \(error)")
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func updateTitle() {
        let text: String
        if let height = service.blockHeight {
            text = "⛏ \(height.formatted(.number.grouping(.automatic)))"
        } else {
            text = "⛏ --"
        }

        let attributed = NSAttributedString(
            string: text,
            attributes: [
                .foregroundColor: NSColor.bitcoinOrange,
                .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .semibold)
            ]
        )
        statusItem.button?.attributedTitle = attributed
    }
}

extension NSColor {
    static let bitcoinOrange = NSColor(
        red: BitcoinPalette.orangeR,
        green: BitcoinPalette.orangeG,
        blue: BitcoinPalette.orangeB,
        alpha: 1
    )
}
