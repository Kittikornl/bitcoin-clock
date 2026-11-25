import AppKit

/// Offers to move the app into /Applications when it is launched from somewhere else
/// (a mounted dmg, Downloads, ...) and then relaunches it from there.
///
/// Running from /Applications keeps the app findable in Spotlight and Launchpad and keeps
/// the launch-at-login registration pointing at a stable path.
@MainActor
enum MoveToApplications {
    private static let suppressKey = "SuppressMoveToApplicationsPrompt"

    /// Returns `true` when the app is moving itself and will quit, so the caller must stop launching.
    static func offerIfNeeded() -> Bool {
        let bundleURL = Bundle.main.bundleURL
        // `swift run` dev builds are a bare executable, not an .app bundle.
        guard bundleURL.pathExtension == "app" else { return false }
        guard !isInApplications(bundleURL) else { return false }
        guard !UserDefaults.standard.bool(forKey: suppressKey) else { return false }

        let alert = NSAlert()
        alert.messageText = "Move Bitcoin Clock to Applications?"
        alert.informativeText = "Bitcoin Clock is running from outside your Applications folder. "
            + "Moving it there makes it easy to find and keeps launch at login working."
        alert.addButton(withTitle: "Move to Applications")
        alert.addButton(withTitle: "Not Now")
        alert.showsSuppressionButton = true
        alert.suppressionButton?.title = "Don't ask again"

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if alert.suppressionButton?.state == .on {
            UserDefaults.standard.set(true, forKey: suppressKey)
        }
        guard response == .alertFirstButtonReturn else { return false }
        return move(from: bundleURL)
    }

    private static func isInApplications(_ url: URL) -> Bool {
        let path = url.standardizedFileURL.path
        let userApplications = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications").path
        return path.hasPrefix("/Applications/") || path.hasPrefix(userApplications + "/")
    }

    private static func move(from source: URL) -> Bool {
        let fm = FileManager.default
        let destination = URL(fileURLWithPath: "/Applications", isDirectory: true)
            .appendingPathComponent(source.lastPathComponent)
        do {
            if fm.fileExists(atPath: destination.path) {
                guard confirmReplace() else { return false }
                quitOtherInstances()
                // To the Trash, never a hard delete: the user can always get the old copy back.
                try fm.trashItem(at: destination, resultingItemURL: nil)
            }
            try fm.copyItem(at: source, to: destination)
            // The user just chose to install this exact app, so the copy should not trigger a
            // second Gatekeeper prompt.
            removexattr(destination.path, "com.apple.quarantine", 0)
        } catch {
            showError("Couldn't move Bitcoin Clock", detail: error.localizedDescription)
            return false
        }
        relaunch(from: destination)
        return true
    }

    private static func confirmReplace() -> Bool {
        let alert = NSAlert()
        alert.messageText = "Replace the copy in Applications?"
        alert.informativeText = "Bitcoin Clock is already in your Applications folder. "
            + "The existing copy will be moved to the Trash."
        alert.addButton(withTitle: "Replace")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }

    private static func quitOtherInstances() {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        let me = ProcessInfo.processInfo.processIdentifier
        for app in NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        where app.processIdentifier != me {
            app.terminate()
        }
    }

    private static func relaunch(from destination: URL) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: destination, configuration: configuration) { _, error in
            Task { @MainActor in
                if let error {
                    showError(
                        "Moved, but couldn't reopen Bitcoin Clock",
                        detail: "Open it from your Applications folder. (\(error.localizedDescription))"
                    )
                }
                NSApp.terminate(nil)
            }
        }
    }

    private static func showError(_ title: String, detail: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = detail
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
