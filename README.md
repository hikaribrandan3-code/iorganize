# iOrganize

iOrganize is a small, local macOS file organizer. I built it to turn repetitive Downloads and screenshot cleanup into reviewable folder rules, then added Smart Sanitize for manual cleanup scans. I still use its cleanup feature. Automatic filing and deletion have been less consistent in my hands-on use, so I present those as useful but still maturing features.

## What it does

- **Auto-Flow:** watch a chosen folder while the app is open; match file type, name, age, size, or screenshot names; move, rename, compress, Trash, delete, open with an app, or run a user-selected script.
- **Smart Sanitize:** scan local cache, log, temporary, Downloads, screenshot, and duplicate candidates. Every category starts unselected. The app previews candidates and asks for confirmation before cleanup.
- **Language packs:** inventory only. iOrganize does not remove files inside `/Applications` app bundles.

## Verified stack and architecture

Swift 6.1 package, SwiftUI/AppKit interface, Foundation file operations and folder watching, CryptoKit SHA-256 for full duplicate verification, and a small static HTML/CSS/JavaScript product page. The native app has no cloud backend, account, telemetry, or paid tier. Rules and activity are stored locally in the app support directory. `ScanEngine` collects candidates, `SafetyGuard` checks cleanup paths, and `RuleEngine` executes selected folder rules.

## Build and download

Requires macOS 14 or later and Xcode 16 with a Swift 6.1 compatible toolchain. See [native build instructions](macos-source/README.md). From `macos-source/`, run `make app` or `make zip`. The generated app is ad-hoc signed and is not notarized, so macOS may prompt before first launch. A new free ZIP is staged for smoke testing; the source build is the public option until that release is published.

## Permissions, safety, and limitations

iOrganize needs access to the folders you select. macOS may prompt for access to Desktop, Downloads, or other protected locations. Built-in cleanup and rules run locally; user-selected scripts can do anything the current Mac account can do, so review them before enabling. Smart Sanitize keeps risky categories opt-in, checks duplicate files with a full hash before and immediately before removal, and shows a Trash/permanent-deletion count. It will not clean app bundles. Automated rules only act on direct children of a selected folder; moving files can still fail due to macOS permissions, inaccessible destinations, or files changing during a scan. Trash files still occupy disk until emptied.

This is a personal utility, not a substitute for backups or a general-purpose disk cleaner. See [development notes](DEVELOPMENT_NOTES.md) for audit details and known limits.

## Development approach

I used AI coding tools while building and revising this project. I chose the product behavior, tested the app in regular use, reviewed the source, and made the safety and documentation changes recorded here. The code is available under the MIT License.
