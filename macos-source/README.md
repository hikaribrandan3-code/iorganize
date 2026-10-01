# iOrganize native app

Source for the macOS app in [`Sources/IOrganize`](Sources/IOrganize). SwiftUI handles the interface; `RuleEngine` watches and applies folder rules; `ScanEngine` gathers cleanup candidates; `SafetyGuard` limits built-in removals. Rules and activity stay on this Mac.

## Requirements

- macOS 14 or later
- Xcode 16 / Swift 6.1 compatible toolchain and Xcode Command Line Tools
- No third-party packages, backend, account, or API key

## Build

From this directory:

```sh
make app                         # dist/iOrganize.app
make zip                         # dist/iOrganize.zip
```

`make app` uses the standard Xcode toolchain. `USE_TOOLCHAIN_FIX=1` is an explicit workaround for a machine with a separately installed local Swift toolchain fix; ordinary builds do not need it. The ZIP contains an ad-hoc signed, unnotarized app. Open it through Finder and follow macOS's first-launch prompt if needed. No app is installed automatically by these commands.

## Focused safety check

The test below uses only files it creates under `/private/tmp`; it never scans or cleans your real folders.

```sh
swiftc Sources/IOrganize/Core/SafetyGuard.swift Tests/SafetyGuardCheck.swift -o /private/tmp/iorganize-safety-check
/private/tmp/iorganize-safety-check
```

## Operation and limits

Smart Sanitize requires scan, category selection, preview, and confirmation. Cache/log/temporary categories delete permanently; document categories move to Trash. Language packs inside app bundles are informational only. Duplicate candidates get complete SHA-256 checks during scan and again before removal. Selected folder rules act only on direct children and reject symlink escapes; scripts remain an advanced user-supplied action with the user's full permissions. An app running with user permissions cannot guarantee that every file operation succeeds: macOS privacy controls, missing files, changed files, and destination permissions can block it. The activity log reports rule failures. Rule scheduling and folder watching operate while iOrganize is open.

The app is free under the MIT License. It is a personal utility with known automatic filing reliability limits, not a backup replacement. See [project history and verification](../DEVELOPMENT_NOTES.md).
