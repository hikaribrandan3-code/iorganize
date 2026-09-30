import AppKit
import SwiftUI

/// Shared app state — owns both engines and the active tab.
@MainActor
final class AppState: ObservableObject {
    @Published var tab: AppTab = .sanitize

    let scanner = ScanEngine()
    let ruleEngine = RuleEngine()

    func scanWithRules() {
        scanner.scan(with: ruleEngine.rules)
    }

    private var triggerTimer: Timer?
    private let triggerURL = AppSupport.directory.appendingPathComponent("trigger")

    init() {
        registerISearchCommands()
        // iSearch commands touch the trigger file; poll it like iCapture does.
        triggerTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkTrigger() }
        }
        // Launched at login by the suite LaunchAgent: hide the window and
        // live in the menu bar; Auto-Flow rules keep running silently.
        if CommandLine.arguments.contains("--background") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NSApp.windows.forEach { $0.orderOut(nil) }
            }
        }
    }

    private func checkTrigger() {
        guard let mode = try? String(contentsOf: triggerURL, encoding: .utf8) else { return }
        try? FileManager.default.removeItem(at: triggerURL)
        openWindow()
        switch mode.trimmingCharacters(in: .whitespacesAndNewlines) {
        case "clean":
            tab = .sanitize
            scanner.reset()
            scanner.scan()
        case "newrule":
            tab = .autoFlow
        default:
            break
        }
    }

    func openWindow() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows where window.title == "iOrganize" {
            window.makeKeyAndOrderFront(nil)
            return
        }
    }

    /// Register suite commands into iSearch (same pattern as iCapture).
    private func registerISearchCommands() {
        guard FileManager.default.fileExists(atPath: "/Applications/iSearch.app") else { return }
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/com.hikari.isearch")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("commands.json")

        var commands: [[String: Any]] = []
        if let data = try? Data(contentsOf: file),
           let parsed = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            commands = parsed
        }
        guard !commands.contains(where: { $0["id"] as? String == "iorganize-clean" }) else { return }

        for (id, name, desc, mode) in [
            ("iorganize-clean", "Clear Caches & Junk", "iOrganize — scan and clean junk files", "clean"),
            ("iorganize-newrule", "Create Auto-Flow Rule", "iOrganize — new file automation rule", "newrule"),
        ] {
            commands.append([
                "id": id,
                "name": name,
                "description": desc,
                "kind": "shell",
                "body": "echo \(mode) > \"\(triggerURL.path)\"",
                "show_output": false,
            ])
        }
        if let data = try? JSONSerialization.data(withJSONObject: commands, options: .prettyPrinted) {
            try? data.write(to: file)
        }
    }
}

@main
struct IOrganizeApp: App {
    @StateObject private var app = AppState()

    var body: some Scene {
        Window("iOrganize", id: "main") {
            MainWindowView()
                .environmentObject(app)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 880, height: 640)

        MenuBarExtra {
            MenuBarContent()
                .environmentObject(app)
        } label: {
            Image(systemName: "sparkles.rectangle.stack")
        }
    }
}

private struct MenuBarContent: View {
    @EnvironmentObject var app: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Open iOrganize") {
            openWindow(id: "main")
            app.openWindow()
        }
        Divider()
        Button("Scan for Junk") {
            openWindow(id: "main")
            app.openWindow()
            app.tab = .sanitize
            app.scanner.reset()
            app.scanner.scan()
        }
        Button(app.ruleEngine.paused ? "Resume Auto-Flow" : "Pause Auto-Flow") {
            app.ruleEngine.paused.toggle()
        }
        Divider()
        Button("Quit iOrganize") {
            NSApp.terminate(nil)
        }
    }
}
