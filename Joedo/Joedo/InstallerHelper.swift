import AppKit

// If Joedo is launched from a mounted DMG or from the user's Downloads folder,
// offer to move it to /Applications on their behalf. Matches the "LetsMove"
// pattern Mac users expect from polished distributable apps.
@MainActor
enum InstallerHelper {

    static func offerMoveToApplicationsIfNeeded() {
        // @AppStorage-style "don't ask again" suppression.
        if UserDefaults.standard.bool(forKey: "joedoSuppressInstallPrompt") { return }

        let bundlePath = Bundle.main.bundlePath

        // Already installed into /Applications (system or user)?
        let installedPrefixes = [
            "/Applications/",
            NSHomeDirectory() + "/Applications/",
            "/System/Applications/",
        ]
        if installedPrefixes.contains(where: { bundlePath.hasPrefix($0) }) { return }

        // Only prompt if running from a DMG or Downloads folder — skip Xcode
        // DerivedData, clone builds, etc. that devs wouldn't want moved.
        let isFromDMG = bundlePath.hasPrefix("/Volumes/")
        let downloads = FileManager.default
            .urls(for: .downloadsDirectory, in: .userDomainMask).first?.path ?? ""
        let isFromDownloads = !downloads.isEmpty && bundlePath.hasPrefix(downloads)
        guard isFromDMG || isFromDownloads else { return }

        let alert = NSAlert()
        alert.messageText = "Move Joedo to Applications?"
        alert.informativeText = isFromDMG
            ? "You're running Joedo from a disk image. Move it to your Applications folder so it's easier to open next time?"
            : "You're running Joedo from Downloads. Move it to your Applications folder so it's easier to open next time?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Move to Applications")
        alert.addButton(withTitle: "Not Now")
        alert.addButton(withTitle: "Don't Ask Again")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            install(from: bundlePath)
        case .alertThirdButtonReturn:
            UserDefaults.standard.set(true, forKey: "joedoSuppressInstallPrompt")
        default:
            break
        }
    }

    // MARK: - Install

    private static func install(from sourcePath: String) {
        let appName = (sourcePath as NSString).lastPathComponent
        let destPath = "/Applications/\(appName)"
        let fm = FileManager.default

        // Replace an existing copy if one is already installed.
        if fm.fileExists(atPath: destPath) {
            let replace = NSAlert()
            replace.messageText = "Joedo is already in Applications."
            replace.informativeText = "Replace the existing version with this one?"
            replace.addButton(withTitle: "Replace")
            replace.addButton(withTitle: "Cancel")
            if replace.runModal() != .alertFirstButtonReturn { return }
            do {
                try fm.removeItem(atPath: destPath)
            } catch {
                showError("Couldn't remove existing copy", error)
                return
            }
        }

        do {
            try fm.copyItem(atPath: sourcePath, toPath: destPath)
        } catch {
            showError("Couldn't move Joedo", error)
            return
        }

        // Launch the copy and quit this instance.
        let destURL = URL(fileURLWithPath: destPath)
        NSWorkspace.shared.openApplication(at: destURL,
                                           configuration: NSWorkspace.OpenConfiguration()) { _, _ in }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            NSApp.terminate(nil)
        }
    }

    private static func showError(_ title: String, _ error: Error) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }
}
