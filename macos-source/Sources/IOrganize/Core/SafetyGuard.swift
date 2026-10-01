import Foundation

/// Guardrails for built-in cleanup and destructive folder rules. User-supplied
/// scripts are arbitrary code and cannot be constrained by these checks.
enum SafetyGuard {
    static let home = FileManager.default.homeDirectoryForCurrentUser.path

    /// Roots we are allowed to delete *children* of.
    static var allowedRoots: [String] {
        [
            home + "/Library/Caches",
            home + "/Library/Logs",
            home + "/Library/Application Support",
            home + "/Downloads",
            home + "/.Trash",
            NSTemporaryDirectory(),
            "/private/tmp",
            "/private/var/tmp",
        ]
    }

    /// Cache/support folders that look like junk but break things when
    /// removed mid-session. Matched by prefix against the folder name.
    static let protectedNames: [String] = [
        "com.apple.bird",            // iCloud Drive daemon
        "CloudKit",
        "com.apple.cloudd",
        "com.apple.Safari.SafeBrowsing",
        "com.apple.HomeKit",
        "com.apple.passd",
        "com.apple.akd",             // AuthKit
        "com.apple.iCloudHelper",
        "FamilyCircle",
        "com.apple.Spotlight",
        "com.apple.LaunchServices",
        "MobileSync",                // device backups live under App Support
        "AddressBook",
        "iMessage",
        "Messages",
        "Mail",
        "Keychains",
    ]

    static func isProtectedName(_ name: String) -> Bool {
        protectedNames.contains { name.hasPrefix($0) }
    }

    /// True only when `url` resolves to a real path strictly inside an
    /// allowed root.
    static func isRemovable(_ url: URL, viaTrash: Bool = false) -> Bool {
        let resolved = url.resolvingSymlinksInPath().standardizedFileURL.path
        guard !resolved.isEmpty, resolved != "/" else { return false }
        let roots = allowedRoots + (viaTrash ? [home + "/Desktop", home + "/Pictures"] : [])
        for root in roots {
            let normalizedRoot = URL(fileURLWithPath: root).resolvingSymlinksInPath().standardizedFileURL.path
            if resolved != normalizedRoot, resolved.hasPrefix(normalizedRoot + "/") {
                let relative = String(resolved.dropFirst(normalizedRoot.count + 1))
                let unsafeResolved = relative.split(separator: "/").contains {
                    let name = String($0)
                    return isProtectedName(name) || name.lowercased().hasSuffix(".app")
                }
                let unsafeOriginal = url.pathComponents.contains {
                    isProtectedName($0) || $0.lowercased().hasSuffix(".app")
                }
                return !unsafeResolved && !unsafeOriginal
            }
        }
        return false
    }

    /// Auto-Flow only acts on a direct child of the user's chosen folder.
    /// Resolve both paths to reject symlink escapes and system folders.
    static func isRuleItem(_ url: URL, in folder: URL) -> Bool {
        let root = folder.resolvingSymlinksInPath().standardizedFileURL
        let item = url.resolvingSymlinksInPath().standardizedFileURL
        let userHome = URL(fileURLWithPath: home).resolvingSymlinksInPath().standardizedFileURL.path
        let tempRoot = URL(fileURLWithPath: "/private/tmp").resolvingSymlinksInPath().standardizedFileURL.path
        let rootPath = root.path
        guard rootPath.hasPrefix(userHome + "/") || rootPath.hasPrefix(tempRoot + "/") else { return false }
        return item.deletingLastPathComponent().path == rootPath
            && !item.pathComponents.contains(where: { $0.lowercased().hasSuffix(".app") })
            && !url.pathComponents.contains(where: { $0.lowercased().hasSuffix(".app") })
    }

    static func isRuleDestination(_ folder: URL) -> Bool {
        let resolved = folder.resolvingSymlinksInPath().standardizedFileURL.path
        let userHome = URL(fileURLWithPath: home).resolvingSymlinksInPath().standardizedFileURL.path
        let tempRoot = URL(fileURLWithPath: "/private/tmp").resolvingSymlinksInPath().standardizedFileURL.path
        return (resolved.hasPrefix(userHome + "/") || resolved.hasPrefix(tempRoot + "/"))
            && !folder.pathComponents.contains(where: { $0.lowercased().hasSuffix(".app") })
    }

    @discardableResult
    static func removeRuleItem(_ url: URL, in folder: URL, viaTrash: Bool) throws -> Int64 {
        guard isRuleItem(url, in: folder) else {
            throw NSError(domain: "iOrganize", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Refused to act outside the watched folder: \(url.path)"
            ])
        }
        let size = FileSizer.size(of: url)
        if viaTrash { try FileManager.default.trashItem(at: url, resultingItemURL: nil) }
        else { try FileManager.default.removeItem(at: url) }
        return size
    }

    /// Remove a file/folder, preferring the Trash when `viaTrash` so the
    /// user can always undo. Returns bytes freed (best effort).
    @discardableResult
    static func remove(_ url: URL, viaTrash: Bool) throws -> Int64 {
        guard isRemovable(url, viaTrash: viaTrash) else {
            throw NSError(domain: "iOrganize", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Refused to delete outside safe roots: \(url.path)"
            ])
        }
        let size = FileSizer.size(of: url)
        if viaTrash {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
        } else {
            try FileManager.default.removeItem(at: url)
        }
        return size
    }
}

/// Fast recursive size calculation.
enum FileSizer {
    static func size(of url: URL) -> Int64 {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { return 0 }

        if !isDir.boolValue {
            let values = try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileSizeKey])
            return Int64(values?.totalFileAllocatedSize ?? values?.fileSize ?? 0)
        }

        var total: Int64 = 0
        let keys: [URLResourceKey] = [.totalFileAllocatedSizeKey, .fileSizeKey, .isRegularFileKey]
        guard let enumerator = fm.enumerator(
            at: url, includingPropertiesForKeys: keys,
            options: [], errorHandler: { _, _ in true }
        ) else { return 0 }

        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: Set(keys)),
                  values.isRegularFile == true else { continue }
            total += Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
        }
        return total
    }

    static func format(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
