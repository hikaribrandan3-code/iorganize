# iOrganize development notes — 30 September 2026

## Project origin and initial development

This is a personal Mac cleanup and file organization utility, built with AI-assisted coding. The initial source already contained a SwiftUI app with rule editing, folder watching, local persistence, cleanup scanners, a website, and a packaging target. This note does not claim that the September pass created those features.

## Hands-on usage

The creator still uses iOrganize and reports that manual cleanup works well. Filing and automatic deletion have not been fully reliable in normal use. No wider user adoption or external performance claim is asserted here.

## Source audit: 30 September 2026

The audit found that cleanup could select files inside `/Applications` app bundles, risky categories started checked, duplicate detection only sampled the start and end of files, and cleanup had no final destructive-action confirmation. Some Auto-Flow actions bypassed the safety guard, script launch was reported as success without checking exit status, and failed rules were silently skipped. The website and README had overbroad safety and reliability language.

## Improvements made

- Removed `/Applications` from cleanup roots and made language-pack results informational only.
- Made cleanup categories opt-in and added confirmation showing Trash and permanent-deletion counts.
- Verified whole-file SHA-256 matches before listing and again before removing duplicate candidates.
- Limited automated rules to direct children of the selected folder, with symlink and app-bundle checks. Rule deletions now use the same selected-folder guard; unsafe destinations are refused.
- Reported rule action failures in the activity log and recorded script exit status asynchronously. Added an advanced-action warning for scripts and permanent-deletion rules.
- Made ordinary builds use the standard Xcode toolchain and corrected documentation and product-page claims.

## Verification performed

The release build and ad-hoc signed app bundle were built locally. A focused compiled safety check used disposable `/private/tmp` files to verify `/Applications` rejection, protected-name rejection, direct-child limits, symlink escape refusal, destination checks, and guarded deletion. It did not access or delete personal files. No broad automated integration suite or fresh manual UI smoke test is claimed.

## Known limitations and current status

Automatic filing and deletion need user smoke testing, especially permissions and destination behavior. A scan can become stale when files change; failures are skipped and logged. User-selected scripts are arbitrary code and are outside built-in guardrails. The binary is ad-hoc signed, unnotarized, and still awaiting the creator's smoke test before public release. The source and build instructions are public. This is a credible small personal utility with explicit safety boundaries, not a production-grade disk cleaner.
