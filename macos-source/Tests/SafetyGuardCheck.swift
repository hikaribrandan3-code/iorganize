import Foundation

@main
struct SafetyGuardCheck {
    static func main() throws {
        let fm = FileManager.default
        let root = URL(fileURLWithPath: "/private/tmp")
            .appendingPathComponent("iOrganize-safety-\(UUID().uuidString)")
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: root) }

        func check(_ condition: Bool, _ message: String) {
            precondition(condition, message)
        }

        check(!SafetyGuard.isRemovable(URL(fileURLWithPath: "/Applications/Example.app/Contents/Resources/en.lproj")),
              "Application bundles must never be cleanup targets")
        let protected = root.appendingPathComponent("com.apple.bird/cache.bin")
        check(!SafetyGuard.isRemovable(protected), "Protected ancestors must be refused")

        let watched = root.appendingPathComponent("watched")
        try fm.createDirectory(at: watched, withIntermediateDirectories: true)
        let file = watched.appendingPathComponent("test.txt")
        try Data("disposable".utf8).write(to: file)
        check(SafetyGuard.isRuleItem(file, in: watched), "Direct child should be eligible")
        check(!SafetyGuard.isRuleItem(root, in: watched), "Parent must not be eligible")
        let outside = root.appendingPathComponent("outside.txt")
        try Data("keep".utf8).write(to: outside)
        let link = watched.appendingPathComponent("escape.txt")
        try fm.createSymbolicLink(at: link, withDestinationURL: outside)
        check(!SafetyGuard.isRuleItem(link, in: watched), "Symlink escape must be refused")
        check(!SafetyGuard.isRuleDestination(URL(fileURLWithPath: "/Applications")),
              "System destination must be refused")

        _ = try SafetyGuard.removeRuleItem(file, in: watched, viaTrash: false)
        check(!fm.fileExists(atPath: file.path), "Disposable fixture should be removed")
        check(fm.fileExists(atPath: outside.path), "Outside fixture must remain")
        print("SafetyGuard checks passed (disposable temporary files only)")
    }
}
