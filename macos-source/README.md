# iOrganize for macOS — source

A SwiftUI file organization utility with Auto-Flow rules and Smart Sanitize scans. The app is free and open source under the MIT License. There are no paid tiers, license checks, account requirements, telemetry, or cloud services in the native app.

## Requirements

- macOS 14 or later
- Xcode 16 / Swift 6.1 toolchain

## Build

From this directory:

```sh
make app
```

The app bundle is written to `dist/iOrganize.app`. To create a ZIP for local distribution, run `make zip`; it writes `dist/iOrganize.zip`. The Makefile applies an ad-hoc signature for local use. The app is not notarized, so macOS may show a first-open security prompt. Review the source before granting the app file access.

## What it does

- Watches selected folders and evaluates user-defined file rules
- Supports conditions and actions such as move, rename, archive, Trash, permanent deletion, open-with, and script execution
- Runs rules on demand and on configured schedules
- Scans selected folders and previews cleanup candidates
- Uses local file access; it has no account, license service, or network backend

This source reflects the recovered project and has not had a formal compatibility or safety audit. Permanent deletion and custom script actions can be destructive; configure rules carefully.
