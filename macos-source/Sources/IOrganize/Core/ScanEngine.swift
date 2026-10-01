import Foundation
import CryptoKit

// MARK: - Model

enum JunkCategory: String, CaseIterable, Identifiable {
    case appCaches, systemLogs, tempFiles, orphanedFiles
    case duplicateDownloads, oldDownloads, languageFiles, browserCaches, trashBin
    case mediaduplicates, streamingJunk, screenshots

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appCaches: return "Application Caches"
        case .systemLogs: return "System Logs"
        case .tempFiles: return "Temporary Files"
        case .orphanedFiles: return "Orphaned Files"
        case .duplicateDownloads: return "Duplicate Downloads"
        case .oldDownloads: return "Old Downloads"
        case .languageFiles: return "Language Files"
        case .browserCaches: return "Browser Caches"
        case .trashBin: return "Trash Bin"
        case .mediaduplicates: return "Duplicate Photos & Videos"
        case .streamingJunk: return "Streaming Temp Files"
        case .screenshots: return "Old Screenshots"
        }
    }

    var symbol: String {
        switch self {
        case .appCaches: return "gearshape.2.fill"
        case .systemLogs: return "doc.text.fill"
        case .tempFiles: return "doc.badge.clock.fill"
        case .orphanedFiles: return "link.badge.plus"
        case .duplicateDownloads: return "doc.on.doc.fill"
        case .oldDownloads: return "clock.arrow.circlepath"
        case .languageFiles: return "flag.fill"
        case .browserCaches: return "safari.fill"
        case .trashBin: return "trash.fill"
        case .mediaduplicates: return "photo.on.rectangle.angled"
        case .streamingJunk: return "film.fill"
        case .screenshots: return "macwindow.on.rectangle"
        }
    }

    var subtitle: String {
        switch self {
        case .appCaches: return "Bloated cache files apps rebuild on demand"
        case .systemLogs: return "Old app and system log files"
        case .tempFiles: return "Leftovers from installs and crashes"
        case .orphanedFiles: return "Support files from uninstalled apps"
        case .duplicateDownloads: return "Identical copies in Downloads"
        case .oldDownloads: return "Downloads untouched for 30+ days"
        case .languageFiles: return "Language packs inside apps (information only)"
        case .browserCaches: return "Safari / Chrome / Firefox caches"
        case .trashBin: return "Files already sitting in the Trash"
        case .mediaduplicates: return "Duplicate photos & videos (keeps most recent)"
        case .streamingJunk: return "Streaming site temp files and Opera cache"
        case .screenshots: return "Screenshots older than 24 hours (review zone 24hrs-30 days)"
        }
    }

    /// Reversible categories go to the Trash; regenerable caches are removed
    /// directly (sending 4 GB of cache to Trash frees nothing).
    var deletesViaTrash: Bool {
        switch self {
        case .appCaches, .systemLogs, .tempFiles, .browserCaches, .trashBin, .streamingJunk:
            return false
        case .orphanedFiles, .duplicateDownloads, .oldDownloads, .languageFiles, .mediaduplicates, .screenshots:
            return true
        }
    }

    /// Categories that touch user documents or app bundles start unchecked —
    /// the user opts in per scan.
    var defaultEnabled: Bool {
        false
    }
}

struct JunkItem: Identifiable {
    let id = UUID()
    let url: URL
    let size: Int64
    let duplicateOf: URL?

    init(url: URL, size: Int64, duplicateOf: URL? = nil) {
        self.url = url
        self.size = size
        self.duplicateOf = duplicateOf
    }
}

struct CategoryResult: Identifiable {
    let category: JunkCategory
    var items: [JunkItem]
    var enabled: Bool

    var id: String { category.rawValue }
    var totalSize: Int64 { items.reduce(0) { $0 + $1.size } }
}

// MARK: - Engine

@MainActor
final class ScanEngine: ObservableObject {
    enum Phase: Equatable {
        case idle
        case scanning(String)          // current category title
        case results
        case cleaning(Double)          // 0...1
        case done(Int64)               // bytes freed
    }

    @Published private(set) var phase: Phase = .idle
    @Published var results: [CategoryResult] = []

    var totalSelectedBytes: Int64 {
        results.filter(\.enabled).reduce(0) { $0 + $1.totalSize }
    }
    var totalFoundBytes: Int64 {
        results.reduce(0) { $0 + $1.totalSize }
    }

    nonisolated private var fm: FileManager { .default }
    nonisolated private let home = FileManager.default.homeDirectoryForCurrentUser

    // MARK: Scan

    func scan(with rules: [AutoRule] = []) {
        guard phase == .idle || phase == .results || isDone else { return }
        results = []
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            for category in JunkCategory.allCases {
                await MainActor.run { self.phase = .scanning(category.title) }
                let items = self.collect(category, with: rules)
                await MainActor.run {
                    self.results.append(CategoryResult(
                        category: category,
                        items: items,
                        enabled: category.defaultEnabled && !items.isEmpty
                    ))
                }
            }
            await MainActor.run { self.phase = .results }
        }
    }

    private var isDone: Bool {
        if case .done = phase { return true }
        return false
    }

    // Runs off-main.
    nonisolated private func collect(_ category: JunkCategory, with rules: [AutoRule]) -> [JunkItem] {
        switch category {
        case .appCaches: return collectCaches()
        case .systemLogs: return collectChildren(of: home.appendingPathComponent("Library/Logs"))
        case .tempFiles: return collectTempFiles()
        case .orphanedFiles: return collectOrphanedSupport()
        case .duplicateDownloads: return collectDuplicateDownloads()
        case .oldDownloads: return collectOldDownloads()
        case .languageFiles: return collectLanguageFiles()
        case .browserCaches: return collectBrowserCaches()
        case .trashBin: return collectChildren(of: home.appendingPathComponent(".Trash"))
        case .mediaduplicates: return collectMediaDuplicates()
        case .streamingJunk: return collectStreamingJunk()
        case .screenshots: return collectScreenshots(with: rules)
        }
    }

    nonisolated private func children(of url: URL) -> [URL] {
        (try? fm.contentsOfDirectory(
            at: url, includingPropertiesForKeys: [.isSymbolicLinkKey],
            options: [.skipsHiddenFiles]
        )) ?? []
    }

    nonisolated private func collectChildren(of url: URL, minBytes: Int64 = 1) -> [JunkItem] {
        children(of: url).compactMap { child in
            guard SafetyGuard.isRemovable(child) else { return nil }
            let size = FileSizer.size(of: child)
            return size >= minBytes ? JunkItem(url: child, size: size) : nil
        }
    }

    nonisolated private func collectCaches() -> [JunkItem] {
        let root = home.appendingPathComponent("Library/Caches")
        // Skip browser caches here — they get their own category.
        let browserPrefixes = ["com.apple.Safari", "Google", "Firefox", "Mozilla", "com.brave", "com.microsoft.edgemac", "Arc", "company.thebrowser"]
        return children(of: root).compactMap { child in
            let name = child.lastPathComponent
            guard !SafetyGuard.isProtectedName(name),
                  !browserPrefixes.contains(where: { name.hasPrefix($0) }),
                  SafetyGuard.isRemovable(child) else { return nil }
            let size = FileSizer.size(of: child)
            return size > 0 ? JunkItem(url: child, size: size) : nil
        }
    }

    nonisolated private func collectBrowserCaches() -> [JunkItem] {
        let cacheRoot = home.appendingPathComponent("Library/Caches")
        let candidates = [
            "com.apple.Safari", "Google/Chrome", "Firefox", "Mozilla",
            "com.brave.Browser", "com.microsoft.edgemac", "company.thebrowser.Browser",
        ]
        return candidates.compactMap { rel in
            let url = cacheRoot.appendingPathComponent(rel)
            guard fm.fileExists(atPath: url.path), SafetyGuard.isRemovable(url) else { return nil }
            let size = FileSizer.size(of: url)
            return size > 0 ? JunkItem(url: url, size: size) : nil
        }
    }

    nonisolated private func collectTempFiles() -> [JunkItem] {
        var items: [JunkItem] = []
        let threeDaysAgo = Date().addingTimeInterval(-3 * 86_400)
        for root in [URL(fileURLWithPath: NSTemporaryDirectory()), URL(fileURLWithPath: "/private/tmp")] {
            for child in children(of: root) {
                guard SafetyGuard.isRemovable(child),
                      fm.isDeletableFile(atPath: child.path) else { continue }
                let values = try? child.resourceValues(forKeys: [.contentModificationDateKey])
                guard let modified = values?.contentModificationDate, modified < threeDaysAgo else { continue }
                let size = FileSizer.size(of: child)
                if size > 0 { items.append(JunkItem(url: child, size: size)) }
            }
        }
        return items
    }

    /// App Support folders named like a reverse-DNS bundle id with no
    /// matching installed app.
    nonisolated private func collectOrphanedSupport() -> [JunkItem] {
        let installedIDs = installedBundleIDs()
        let root = home.appendingPathComponent("Library/Application Support")
        return children(of: root).compactMap { child in
            let name = child.lastPathComponent
            // Only reverse-DNS style names — plain-named folders (e.g.
            // "Google", "Code") are too ambiguous to call orphaned.
            guard name.components(separatedBy: ".").count >= 3,
                  !name.hasPrefix("com.apple."),
                  !SafetyGuard.isProtectedName(name),
                  !installedIDs.contains(name.lowercased()),
                  SafetyGuard.isRemovable(child) else { return nil }
            let size = FileSizer.size(of: child)
            return size > 1_000_000 ? JunkItem(url: child, size: size) : nil
        }
    }

    nonisolated private func installedBundleIDs() -> Set<String> {
        var ids = Set<String>()
        var roots = [URL(fileURLWithPath: "/Applications"),
                     home.appendingPathComponent("Applications"),
                     URL(fileURLWithPath: "/Applications/Utilities"),
                     URL(fileURLWithPath: "/System/Applications")]
        // One level of subfolders inside /Applications (e.g. vendor folders)
        roots += children(of: URL(fileURLWithPath: "/Applications"))
            .filter { $0.hasDirectoryPath && $0.pathExtension != "app" }
        for root in roots {
            for app in children(of: root) where app.pathExtension == "app" {
                if let id = Bundle(url: app)?.bundleIdentifier {
                    ids.insert(id.lowercased())
                }
            }
        }
        return ids
    }

    nonisolated private func collectDuplicateDownloads() -> [JunkItem] {
        let downloads = home.appendingPathComponent("Downloads")
        var bySize: [Int64: [URL]] = [:]
        for child in children(of: downloads) {
            let values = try? child.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
            guard values?.isRegularFile == true, let size = values?.fileSize, size > 4096 else { continue }
            bySize[Int64(size), default: []].append(child)
        }
        var duplicates: [JunkItem] = []
        for (size, urls) in bySize where urls.count > 1 {
            var byHash: [String: [URL]] = [:]
            for url in urls {
                if let hash = quickHash(url) { byHash[hash, default: []].append(url) }
            }
            for (_, dupes) in byHash where dupes.count > 1 {
                // Keep the newest copy; the rest are junk.
                let sorted = dupes.sorted {
                    let a = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                    let b = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                    return a > b
                }
                let verified = Dictionary(grouping: sorted, by: { fullHash($0) ?? UUID().uuidString })
                for group in verified.values where group.count > 1 {
                    let keeper = group[0]
                    duplicates += group.dropFirst().map { JunkItem(url: $0, size: size, duplicateOf: keeper) }
                }
            }
        }
        return duplicates
    }

    /// SHA-256 of size + first and last 256 KB — enough to separate
    /// same-size files without reading multi-GB downloads end to end.
    nonisolated private func quickHash(_ url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        var hasher = SHA256()
        let chunk = 256 * 1024
        guard let head = try? handle.read(upToCount: chunk) else { return nil }
        hasher.update(data: head)
        if let size = try? handle.seekToEnd(), size > UInt64(chunk * 2) {
            try? handle.seek(toOffset: size - UInt64(chunk))
            if let tail = try? handle.read(upToCount: chunk) { hasher.update(data: tail) }
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    /// Stream the complete file before calling a duplicate safe to remove.
    nonisolated private func fullHash(_ url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        var hasher = SHA256()
        do {
            while let data = try handle.read(upToCount: 1024 * 1024), !data.isEmpty {
                hasher.update(data: data)
            }
            return hasher.finalize().map { String(format: "%02x", $0) }.joined()
        } catch { return nil }
    }

    nonisolated private func stillDuplicate(_ item: JunkItem) -> Bool {
        guard let keeper = item.duplicateOf,
              let first = fullHash(item.url), let second = fullHash(keeper) else { return false }
        return first == second
    }

    nonisolated private func collectOldDownloads() -> [JunkItem] {
        let downloads = home.appendingPathComponent("Downloads")
        let cutoff = Date().addingTimeInterval(-30 * 86_400)
        return children(of: downloads).compactMap { child in
            let keys: Set<URLResourceKey> = [.contentAccessDateKey, .contentModificationDateKey]
            guard let values = try? child.resourceValues(forKeys: keys) else { return nil }
            let lastTouched = max(values.contentAccessDate ?? .distantPast,
                                  values.contentModificationDate ?? .distantPast)
            guard lastTouched < cutoff, SafetyGuard.isRemovable(child) else { return nil }
            let size = FileSizer.size(of: child)
            return size > 0 ? JunkItem(url: child, size: size) : nil
        }
    }

    /// Informational inventory only. Removing files inside app bundles can
    /// invalidate signatures or break updates, so cleanup never selects them.
    nonisolated private func collectLanguageFiles() -> [JunkItem] {
        let keep: Set<String> = ["en", "english", "base", "es", "pt", "pt-br",
                                 Locale.current.language.languageCode?.identifier.lowercased() ?? "en"]
        var items: [JunkItem] = []
        for app in children(of: URL(fileURLWithPath: "/Applications")) where app.pathExtension == "app" {
            guard let bundleID = Bundle(url: app)?.bundleIdentifier,
                  !bundleID.hasPrefix("com.apple.") else { continue }
            let resources = app.appendingPathComponent("Contents/Resources")
            for child in children(of: resources) where child.pathExtension == "lproj" {
                let lang = child.deletingPathExtension().lastPathComponent.lowercased()
                guard !keep.contains(lang), !keep.contains(lang.components(separatedBy: "-").first ?? lang) else { continue }
                let size = FileSizer.size(of: child)
                if size > 50_000 { items.append(JunkItem(url: child, size: size)) }
            }
        }
        return items
    }

    // MARK: Clean

    func toggle(_ category: JunkCategory) {
        guard category != .languageFiles else { return }
        guard let index = results.firstIndex(where: { $0.category == category }) else { return }
        results[index].enabled.toggle()
    }

    func clean() {
        guard case .results = phase else { return }
        let selected = results.filter { $0.enabled && !$0.items.isEmpty && $0.category != .languageFiles }
        guard !selected.isEmpty else { return }
        phase = .cleaning(0)

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            var freed: Int64 = 0
            var failed = 0
            var movedToTrash = 0
            let totalItems = selected.reduce(0) { $0 + $1.items.count }
            var processed = 0

            for result in selected {
                for item in result.items {
                    if item.duplicateOf != nil && !self.stillDuplicate(item) {
                        failed += 1
                    } else {
                        do {
                            let bytes = try SafetyGuard.remove(item.url, viaTrash: result.category.deletesViaTrash)
                            if result.category.deletesViaTrash { movedToTrash += 1 }
                            else { freed += bytes }
                        } catch { failed += 1 }
                    }
                    processed += 1
                    let progress = Double(processed) / Double(totalItems)
                    await MainActor.run { self.phase = .cleaning(progress) }
                }
            }

            let totalFreed = freed
            let totalFailed = failed
            let totalTrashed = movedToTrash
            await MainActor.run {
                self.phase = .done(totalFreed)
                ActivityLog.shared.add(rule: "Smart Sanitize",
                                       message: "Freed \(FileSizer.format(totalFreed)); moved \(totalTrashed) to Trash; skipped \(totalFailed)")
            }
        }
    }

    func reset() {
        phase = .idle
        results = []
    }

    // MARK: - New categories: Media duplicates, Streaming junk, Screenshots

    nonisolated private func collectMediaDuplicates() -> [JunkItem] {
        var items: [JunkItem] = []
        let mediaExtensions = Set(["jpg", "jpeg", "png", "gif", "heic", "heif", "webp", "mp4", "mov", "m4v", "avi", "mkv"])
        let searchPaths = [
            home.appendingPathComponent("Downloads"),
            home.appendingPathComponent("Pictures"),
            home.appendingPathComponent("Desktop")
        ]

        var byHash: [String: [(URL, Int64)]] = [:]
        for searchPath in searchPaths {
            for child in children(of: searchPath) {
                let ext = child.pathExtension.lowercased()
                guard mediaExtensions.contains(ext) else { continue }
                let size = FileSizer.size(of: child)
                guard size > 4096 else { continue }
                if let hash = quickHash(child) {
                    byHash[hash, default: []].append((child, size))
                }
            }
        }

        for (_, urls) in byHash where urls.count > 1 {
            let sorted = urls.sorted { a, b in
                let aDate = (try? a.0.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                let bDate = (try? b.0.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                return aDate > bDate
            }
            let verified = Dictionary(grouping: sorted, by: { fullHash($0.0) ?? UUID().uuidString })
            for group in verified.values where group.count > 1 {
                let keeper = group[0].0
                for (url, size) in group.dropFirst() {
                    items.append(JunkItem(url: url, size: size, duplicateOf: keeper))
                }
            }
        }
        return items
    }

    nonisolated private func collectStreamingJunk() -> [JunkItem] {
        var items: [JunkItem] = []
        let downloads = home.appendingPathComponent("Downloads")
        let streamingPatterns = [".m3u8", ".ts", ".flv", ".crdownload", ".download"]
        let operaPatterns = ["opera.", ".opera"]

        for child in children(of: downloads) {
            let name = child.lastPathComponent.lowercased()
            let ext = child.pathExtension.lowercased()

            let isStreaming = streamingPatterns.contains("." + ext) ||
                streamingPatterns.contains { name.hasSuffix($0) }
            let isOpera = operaPatterns.contains { name.contains($0) }

            guard isStreaming || isOpera, SafetyGuard.isRemovable(child) else { continue }
            let size = FileSizer.size(of: child)
            if size > 0 { items.append(JunkItem(url: child, size: size)) }
        }

        // Also check Opera cache
        let operaCache = home.appendingPathComponent("Library/Caches/com.operasoftware.Opera")
        for child in children(of: operaCache) {
            guard SafetyGuard.isRemovable(child) else { continue }
            let size = FileSizer.size(of: child)
            if size > 0 { items.append(JunkItem(url: child, size: size)) }
        }

        return items
    }

    nonisolated private func collectScreenshots(with rules: [AutoRule]) -> [JunkItem] {
        var items: [JunkItem] = []
        let reviewStartDays: Int = 1

        // Check if any Auto-Flow rules target screenshots and get their threshold
        let screenshotRuleThreshold = rules
            .filter { rule in
                rule.conditions.contains { condition in
                    if case .isScreenshot = condition { return true }
                    return false
                }
            }
            .compactMap { rule -> Int? in
                rule.conditions.compactMap { condition -> Int? in
                    if case .olderThanDays(let days) = condition { return days }
                    return nil
                }.min()
            }
            .min() ?? reviewStartDays

        let cutoffReview = Date().addingTimeInterval(-Double(screenshotRuleThreshold) * 86_400)

        let searchPaths = [
            home.appendingPathComponent("Downloads"),
            home.appendingPathComponent("Desktop"),
            home.appendingPathComponent("Pictures"),
        ]

        for searchPath in searchPaths {
            for child in children(of: searchPath) {
                guard child.pathExtension.lowercased() == "png",
                      RuleCondition.looksLikeScreenshot(child),
                      SafetyGuard.isRemovable(child) else { continue }

                let values = try? child.resourceValues(forKeys: [.contentModificationDateKey])
                guard let modified = values?.contentModificationDate else { continue }

                // Collect screenshots matching Auto-Flow rules (if any), or default to 24 hours
                guard modified < cutoffReview else { continue }

                // For Auto-Flow (in Auto-Flow rules), we auto-delete based on rule threshold
                // For Smart Sanitize, we show all matching rule criteria for user review
                let size = FileSizer.size(of: child)
                if size > 0 { items.append(JunkItem(url: child, size: size)) }
            }
        }

        return items
    }
}
