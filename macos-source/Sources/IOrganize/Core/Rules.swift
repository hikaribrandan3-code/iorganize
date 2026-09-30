import Foundation

// MARK: - Conditions

enum RuleCondition: Codable, Hashable, Identifiable {
    case fileExtension(String)     // "dmg" (no dot)
    case nameContains(String)
    case olderThanDays(Int)
    case largerThanMB(Int)
    case isScreenshot

    var id: String { summary }

    /// A PNG's extension alone doesn't make it a screenshot — check the
    /// filename too, so arbitrary saved images aren't swept up as junk.
    static func looksLikeScreenshot(_ url: URL) -> Bool {
        let name = url.lastPathComponent
        return name.localizedCaseInsensitiveContains("screenshot")
            || name.localizedCaseInsensitiveContains("screen shot")
            || name.localizedCaseInsensitiveContains("captura")
    }

    var summary: String {
        switch self {
        case .fileExtension(let ext): return "File type is .\(ext)"
        case .nameContains(let text): return "Name contains “\(text)”"
        case .olderThanDays(let days): return "Older than \(days) day\(days == 1 ? "" : "s")"
        case .largerThanMB(let mb): return "Larger than \(mb) MB"
        case .isScreenshot: return "File is a screenshot"
        }
    }

    func matches(_ url: URL) -> Bool {
        switch self {
        case .fileExtension(let ext):
            return url.pathExtension.lowercased() == ext.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
        case .nameContains(let text):
            return url.lastPathComponent.localizedCaseInsensitiveContains(text)
        case .olderThanDays(let days):
            let keys: Set<URLResourceKey> = [.creationDateKey, .contentModificationDateKey]
            guard let values = try? url.resourceValues(forKeys: keys) else { return false }
            let newest = max(values.creationDate ?? .distantPast,
                             values.contentModificationDate ?? .distantPast)
            return newest < Date().addingTimeInterval(-Double(days) * 86_400)
        case .largerThanMB(let mb):
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return size > mb * 1_000_000
        case .isScreenshot:
            return Self.looksLikeScreenshot(url)
        }
    }
}

// MARK: - Actions

enum RuleAction: Codable, Hashable {
    case moveToFolder(String)
    case rename(String)            // pattern with {date} {name} {ext}
    case compress                  // zip next to the file, original → Trash
    case moveToTrash
    case deletePermanently
    case openWith(String)          // .app path
    case runScript(String)         // script path, file path passed as $1

    var summary: String {
        switch self {
        case .moveToFolder(let path):
            return "Move to “\((path as NSString).lastPathComponent)” folder"
        case .rename(let pattern): return "Rename to \(pattern)"
        case .compress: return "Archive (zip)"
        case .moveToTrash: return "Move to Trash"
        case .deletePermanently: return "Delete permanently"
        case .openWith(let app):
            return "Open with \((app as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: ""))"
        case .runScript(let script):
            return "Run script \((script as NSString).lastPathComponent)"
        }
    }
}

// MARK: - Schedule

enum RuleSchedule: String, Codable, CaseIterable, Identifiable {
    case immediate, hourly, daily, weekly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .immediate: return "Immediately when a file matches"
        case .hourly: return "Every hour"
        case .daily: return "Once a day"
        case .weekly: return "Once a week"
        }
    }

    var interval: TimeInterval? {
        switch self {
        case .immediate: return nil
        case .hourly: return 3_600
        case .daily: return 86_400
        case .weekly: return 7 * 86_400
        }
    }
}

// MARK: - Rule

struct AutoRule: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var enabled = true
    var folder: String                 // watched folder (absolute path)
    var matchAll = true                // AND vs OR across conditions
    var conditions: [RuleCondition]
    var action: RuleAction
    var schedule: RuleSchedule = .immediate
    var lastRun: Date?

    func matches(_ url: URL) -> Bool {
        guard !conditions.isEmpty else { return false }
        return matchAll
            ? conditions.allSatisfy { $0.matches(url) }
            : conditions.contains { $0.matches(url) }
    }

    var folderDisplayName: String {
        (folder as NSString).lastPathComponent
    }
}

// MARK: - Activity log

struct ActivityEntry: Codable, Identifiable {
    var id = UUID()
    let date: Date
    let rule: String
    let message: String
}

@MainActor
final class ActivityLog: ObservableObject {
    static let shared = ActivityLog()

    @Published private(set) var entries: [ActivityEntry] = []

    private let fileURL = AppSupport.directory.appendingPathComponent("activity.json")

    private init() {
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([ActivityEntry].self, from: data) {
            entries = saved
        }
    }

    func add(rule: String, message: String) {
        entries.insert(ActivityEntry(date: Date(), rule: rule, message: message), at: 0)
        if entries.count > 200 { entries = Array(entries.prefix(200)) }
        if let data = try? JSONEncoder().encode(entries) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}

// MARK: - App support dir

enum AppSupport {
    static let directory: URL = {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/com.hikari.iorganize")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()
}
