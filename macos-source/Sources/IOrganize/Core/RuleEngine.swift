import AppKit
import Foundation

/// The Auto-Flow brain: persists rules, watches their folders via FSEvents,
/// sweeps age/schedule-based rules on a slow timer, and executes actions.
@MainActor
final class RuleEngine: ObservableObject {
    @Published var rules: [AutoRule] = [] {
        didSet {
            save()
            rebuildWatchers()
        }
    }
    @Published var paused = false {
        didSet {
            if !paused { evaluateAll() }
        }
    }

    private let fileURL = AppSupport.directory.appendingPathComponent("rules.json")
    private var watchers: [String: FolderWatcher] = [:]
    private var sweepTimer: Timer?
    /// Files that failed an action this session — don't retry in a loop.
    private var skiplist = Set<String>()

    init() {
        load()
        rebuildWatchers()
        // Age-based conditions ("older than 7 days") and non-immediate
        // schedules can't be event-driven — a slow sweep catches them.
        sweepTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.evaluateAll() }
        }
        evaluateAll()
    }

    // MARK: Persistence

    private func load() {
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([AutoRule].self, from: data) {
            rules = saved
            return
        }
        // First launch: seed the starter rules, all OFF. A rule that acts on
        // real files must be reviewed and switched on by the user first.
        let downloads = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Downloads").path
        let desktop = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop").path
        rules = [
            AutoRule(
                name: "Move .dmg files to Trash after 7 days",
                enabled: false,
                folder: downloads,
                conditions: [.fileExtension("dmg"), .olderThanDays(7)],
                action: .moveToTrash
            ),
            AutoRule(
                name: "Archive screenshots to Backup folder after 2 weeks",
                enabled: false,
                folder: desktop,
                conditions: [.isScreenshot, .olderThanDays(14)],
                action: .moveToFolder(desktop + "/Backup")
            ),
            AutoRule(
                name: "Delete old downloads after 30 days",
                enabled: false,
                folder: downloads,
                conditions: [.olderThanDays(30)],
                action: .deletePermanently
            ),
        ]
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(rules) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    // MARK: CRUD

    func upsert(_ rule: AutoRule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
        } else {
            rules.append(rule)
        }
    }

    func delete(_ rule: AutoRule) {
        rules.removeAll { $0.id == rule.id }
    }

    func toggle(_ rule: AutoRule) {
        guard let index = rules.firstIndex(where: { $0.id == rule.id }) else { return }
        rules[index].enabled.toggle()
    }

    // MARK: Watching

    private func rebuildWatchers() {
        let folders = Set(rules.filter(\.enabled).map(\.folder))
        watchers = watchers.filter { folders.contains($0.key) }
        for folder in folders where watchers[folder] == nil {
            watchers[folder] = FolderWatcher(path: folder) { [weak self] in
                Task { @MainActor in self?.folderChanged(folder) }
            }
        }
    }

    private func folderChanged(_ folder: String) {
        guard !paused else { return }
        for rule in rules where rule.enabled && rule.folder == folder && rule.schedule == .immediate {
            run(rule)
        }
    }

    func evaluateAll() {
        guard !paused else { return }
        for rule in rules where rule.enabled {
            if let interval = rule.schedule.interval {
                let last = rule.lastRun ?? .distantPast
                guard Date().timeIntervalSince(last) >= interval else { continue }
            }
            run(rule)
        }
    }

    // MARK: Execution

    private func run(_ rule: AutoRule) {
        let folderURL = URL(fileURLWithPath: rule.folder)
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: [.isRegularFileKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        // Never act on in-flight downloads.
        let busyExtensions: Set<String> = ["crdownload", "download", "part", "partial", "tmp"]

        var acted = 0
        var failures = 0
        var lastMessage = ""
        for url in contents {
            guard !busyExtensions.contains(url.pathExtension.lowercased()),
                  !skiplist.contains(url.path),
                  SafetyGuard.isRuleItem(url, in: folderURL),
                  rule.matches(url) else { continue }
            do {
                lastMessage = try execute(rule.action, on: url, in: folderURL)
                acted += 1
            } catch {
                skiplist.insert(url.path)
                failures += 1
                ActivityLog.shared.add(rule: rule.name,
                                       message: "Skipped \(url.lastPathComponent): \(error.localizedDescription)")
            }
        }

        if let index = rules.firstIndex(where: { $0.id == rule.id }), rule.schedule != .immediate {
            // Direct array-element write; the didSet save is fine, but avoid
            // triggering a watcher rebuild storm by only stamping on change.
            rules[index].lastRun = Date()
        }

        if acted > 0 {
            let summary = acted == 1
                ? lastMessage
                : "\(acted) files — \(rule.action.summary.lowercased())"
            ActivityLog.shared.add(rule: rule.name, message: summary)
        }
        if failures > 0 && acted == 0 {
            ActivityLog.shared.add(rule: rule.name, message: "\(failures) file action(s) failed; review the activity log")
        }
    }

    /// Performs one action on one file. Throws on failure so the caller can
    /// skiplist the file. Returns a human summary for the activity log.
    private func execute(_ action: RuleAction, on url: URL, in folder: URL) throws -> String {
        let fm = FileManager.default
        guard SafetyGuard.isRuleItem(url, in: folder) else {
            throw NSError(domain: "iOrganize", code: 5, userInfo: [NSLocalizedDescriptionKey: "File escaped the watched folder"])
        }
        switch action {
        case .moveToFolder(let path):
            let destDir = URL(fileURLWithPath: path)
            guard SafetyGuard.isRuleDestination(destDir) else {
                throw NSError(domain: "iOrganize", code: 6, userInfo: [NSLocalizedDescriptionKey: "Destination must be inside your home folder"])
            }
            try fm.createDirectory(at: destDir, withIntermediateDirectories: true)
            let dest = uniqueDestination(destDir.appendingPathComponent(url.lastPathComponent))
            try fm.moveItem(at: url, to: dest)
            return "\(url.lastPathComponent) → \(destDir.lastPathComponent)/"

        case .rename(let pattern):
            let newName = expand(pattern, for: url)
            guard newName != url.lastPathComponent, !newName.isEmpty,
                  newName != ".", newName != "..", !newName.contains("/") else {
                throw NSError(domain: "iOrganize", code: 2)
            }
            let dest = uniqueDestination(url.deletingLastPathComponent().appendingPathComponent(newName))
            try fm.moveItem(at: url, to: dest)
            return "Renamed to \(dest.lastPathComponent)"

        case .compress:
            guard url.pathExtension.lowercased() != "zip" else {
                throw NSError(domain: "iOrganize", code: 3)
            }
            let zipURL = uniqueDestination(url.deletingPathExtension().appendingPathExtension("zip"))
            let ditto = Process()
            ditto.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            ditto.arguments = ["-c", "-k", "--sequesterRsrc", url.path, zipURL.path]
            try ditto.run()
            ditto.waitUntilExit()
            guard ditto.terminationStatus == 0 else {
                throw NSError(domain: "iOrganize", code: 4)
            }
            _ = try SafetyGuard.removeRuleItem(url, in: folder, viaTrash: true)
            return "\(url.lastPathComponent) → \(zipURL.lastPathComponent)"

        case .moveToTrash:
            _ = try SafetyGuard.removeRuleItem(url, in: folder, viaTrash: true)
            return "\(url.lastPathComponent) moved to Trash"

        case .deletePermanently:
            _ = try SafetyGuard.removeRuleItem(url, in: folder, viaTrash: false)
            return "\(url.lastPathComponent) deleted"

        case .openWith(let appPath):
            NSWorkspace.shared.open(
                [url], withApplicationAt: URL(fileURLWithPath: appPath),
                configuration: NSWorkspace.OpenConfiguration()
            )
            // Prevent re-opening the same file on every sweep.
            skiplist.insert(url.path)
            return "\(url.lastPathComponent) opened"

        case .runScript(let scriptPath):
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/bin/zsh")
            proc.arguments = [scriptPath, url.path]
            let fileName = url.lastPathComponent
            proc.terminationHandler = { finished in
                let status = finished.terminationStatus
                Task { @MainActor in
                    ActivityLog.shared.add(rule: "Script",
                                           message: "\(fileName): exit status \(status)")
                }
            }
            try proc.run()
            skiplist.insert(url.path)
            return "Script started on \(url.lastPathComponent)"
        }
    }

    private func uniqueDestination(_ url: URL) -> URL {
        var candidate = url
        var counter = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            let base = url.deletingPathExtension().lastPathComponent
            let ext = url.pathExtension
            let name = ext.isEmpty ? "\(base) \(counter)" : "\(base) \(counter).\(ext)"
            candidate = url.deletingLastPathComponent().appendingPathComponent(name)
            counter += 1
        }
        return candidate
    }

    private func expand(_ pattern: String, for url: URL) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let ext = url.pathExtension
        var name = pattern
            .replacingOccurrences(of: "{date}", with: formatter.string(from: Date()))
            .replacingOccurrences(of: "{name}", with: url.deletingPathExtension().lastPathComponent)
            .replacingOccurrences(of: "{ext}", with: ext)
        if !ext.isEmpty && !name.lowercased().hasSuffix(".\(ext.lowercased())") {
            name += ".\(ext)"
        }
        return name
    }
}
