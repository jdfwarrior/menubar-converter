import AppKit
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var statusMenu: NSMenu!
    private var convertingMenuItem: NSMenuItem?
    private let converter = Converter()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        NotificationCenter.default.addObserver(self, selector: #selector(updateStatus(_:)), name: .MBConverterStatusChange, object: nil)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            if granted { Logger.shared.log("Notifications authorized") }
        }
        converter.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        converter.stop()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusMenu = NSMenu()
        convertingMenuItem = NSMenuItem(title: "Converting: idle", action: nil, keyEquivalent: "")
        convertingMenuItem?.isEnabled = false
        if let cm = convertingMenuItem { statusMenu.addItem(cm) }
        statusMenu.addItem(NSMenuItem.separator())
        statusMenu.addItem(NSMenuItem(title: "Open Logs", action: #selector(openLogs), keyEquivalent: "l"))
        statusMenu.addItem(NSMenuItem.separator())
        statusMenu.addItem(NSMenuItem(title: "Quit MBConverter", action: #selector(quit), keyEquivalent: "q"))

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "film", accessibilityDescription: "MBConverter")
            button.action = #selector(statusClicked)
            button.target = self
            button.toolTip = "MBConverter: idle"
        }
        statusItem.menu = statusMenu
    }

    @objc private func statusClicked() {
        // show menu
    }

    @objc private func openLogs() {
        NSWorkspace.shared.open(Logger.shared.logsDirectory)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    @objc private func updateStatus(_ note: Notification) {
        guard let info = note.userInfo as? [String: Any] else { return }
        let state = info["state"] as? String ?? "idle"
        let filename = info["filename"] as? String ?? ""

        DispatchQueue.main.async {
            if state == "converting" {
                self.convertingMenuItem?.title = "Converting: \(filename)"
                if let button = self.statusItem.button {
                    button.image = NSImage(systemSymbolName: "arrow.triangle.2.circlepath", accessibilityDescription: "converting")
                    button.toolTip = "Converting \(filename)"
                }
            } else {
                self.convertingMenuItem?.title = "Converting: idle"
                if let button = self.statusItem.button {
                    button.image = NSImage(systemSymbolName: "film", accessibilityDescription: "MBConverter")
                    button.toolTip = "MBConverter: idle"
                }
            }
        }
    }
}

extension Notification.Name {
    static let MBConverterStatusChange = Notification.Name("MBConverterStatusChange")
}
