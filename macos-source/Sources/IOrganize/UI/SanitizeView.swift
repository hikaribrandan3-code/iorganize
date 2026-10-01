import SwiftUI

/// Tab 1 — Smart Sanitize: scan → review categories → clean → freed report.
struct SanitizeView: View {
    @EnvironmentObject var scanner: ScanEngine
    @EnvironmentObject var app: AppState
    @State private var previewingCategory: JunkCategory?
    @State private var showingCleanupConfirmation = false

    var body: some View {
        VStack(spacing: 20) {
            switch scanner.phase {
            case .idle:
                idleState
            case .scanning(let label):
                scanningState(label)
            case .results, .cleaning, .done:
                resultsState
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheet(item: $previewingCategory) { category in
            if let result = scanner.results.first(where: { $0.category == category }) {
                CategoryDetailView(result: result)
                    .environmentObject(scanner)
            }
        }
        .alert("Review cleanup", isPresented: $showingCleanupConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clean Selected Files", role: .destructive) { scanner.clean() }
        } message: {
            Text("\(selectedItemCount) items selected. \(trashItemCount) will move to Trash and \(permanentItemCount) will be deleted permanently. Review each category before continuing.")
        }
    }

    // MARK: Idle

    private var idleState: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundStyle(Theme.gold)
            Text("Review cleanup candidates on your Mac")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("iOrganize scans caches, logs, temp files, duplicates and more.\nEverything runs locally — nothing ever leaves this Mac.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            scanButton
            Spacer()
            Spacer()
        }
    }

    private var scanButton: some View {
        Button {
            app.scanWithRules()
        } label: {
            Label("Scan for Junk", systemImage: "wand.and.sparkles")
                .font(.system(size: 15, weight: .semibold))
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .background(Theme.gold, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .foregroundStyle(Color.black.opacity(0.85))
        }
        .buttonStyle(.plain)
    }

    // MARK: Scanning

    private func scanningState(_ label: String) -> some View {
        VStack(spacing: 18) {
            Spacer()
            ProgressView()
                .controlSize(.large)
                .tint(Theme.gold)
            Text("Scanning \(label)…")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
            if !scanner.results.isEmpty {
                Text("Found so far: \(FileSizer.format(scanner.totalFoundBytes))")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            Spacer()
        }
    }

    // MARK: Results / cleaning / done

    private var resultsState: some View {
        VStack(spacing: 18) {
            scanButtonSmall

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(scanner.results) { result in
                        Button {
                            if !result.items.isEmpty {
                                previewingCategory = result.category
                            }
                        } label: {
                            CategoryRow(result: result)
                        }
                        .buttonStyle(.plain)
                        .environmentObject(scanner)
                        if result.id != scanner.results.last?.id {
                            Divider().overlay(Theme.cardStroke)
                        }
                    }
                    Divider().overlay(Theme.cardStroke)
                    totalRow
                }
                .padding(.vertical, 6)
                .card()
            }

            footer
        }
    }

    private var scanButtonSmall: some View {
        Button {
            scanner.reset()
            app.scanWithRules()
        } label: {
            Label("Scan Again", systemImage: "arrow.clockwise")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.goldSoft)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .opacity(isBusy ? 0 : 1)
    }

    private var totalRow: some View {
        HStack {
            Text("Selected Size:")
                .font(.system(size: 15, weight: .bold))
            Spacer()
            Text(FileSizer.format(scanner.totalSelectedBytes))
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.gold)
        }
        .foregroundStyle(Theme.textPrimary)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private var isBusy: Bool {
        if case .cleaning = scanner.phase { return true }
        return false
    }

    private var selectedItemCount: Int { trashItemCount + permanentItemCount }
    private var trashItemCount: Int {
        scanner.results.filter { $0.enabled && $0.category.deletesViaTrash && $0.category != .languageFiles }
            .reduce(0) { $0 + $1.items.count }
    }
    private var permanentItemCount: Int {
        scanner.results.filter { $0.enabled && !$0.category.deletesViaTrash }
            .reduce(0) { $0 + $1.items.count }
    }

    @ViewBuilder
    private var footer: some View {
        switch scanner.phase {
        case .results:
            Button {
                showingCleanupConfirmation = true
            } label: {
                Label("Clean Now", systemImage: "trash.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(
                        scanner.totalSelectedBytes > 0 ? Theme.danger : Theme.card,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .foregroundStyle(scanner.totalSelectedBytes > 0 ? .white : Theme.textTertiary)
            }
            .buttonStyle(.plain)
            .disabled(scanner.totalSelectedBytes == 0)

        case .cleaning(let progress):
            VStack(spacing: 10) {
                ProgressView(value: progress)
                    .tint(Theme.gold)
                    .frame(maxWidth: 420)
                Text("Cleaning… \(Int(progress * 100))%")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }

        case .done(let freed):
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    Rectangle().fill(Theme.gold).frame(height: 4).clipShape(Capsule())
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.success)
                    Rectangle().fill(Theme.gold).frame(height: 4).clipShape(Capsule())
                }
                .frame(maxWidth: 460)
                Text("Cleanup complete. \(FileSizer.format(freed)) permanently freed; Trash items still occupy space.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
            }

        default:
            EmptyView()
        }
    }
}

// MARK: - Category row

// MARK: - Category detail preview

struct CategoryDetailView: View {
    let result: CategoryResult
    @EnvironmentObject var scanner: ScanEngine
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.gold)
                }
                .buttonStyle(.plain)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(result.category.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(result.items.count) files • \(FileSizer.format(result.totalSize))")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(20)
            .background(Theme.sidebarBackground)

            Divider().overlay(Theme.cardStroke)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(result.items) { item in
                        HStack(spacing: 12) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textTertiary)
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.url.lastPathComponent)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Theme.textPrimary)
                                    .lineLimit(1)
                                Text(item.url.path)
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.textTertiary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text(FileSizer.format(item.size))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)
                                .frame(minWidth: 60, alignment: .trailing)
                        }
                        .padding(12)
                        .background(Theme.card)
                        .cornerRadius(8)
                    }
                }
                .padding(20)
            }

            Divider().overlay(Theme.cardStroke)

            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Got it")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Theme.gold, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .foregroundStyle(Color.black.opacity(0.85))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .frame(minWidth: 500, minHeight: 400)
        .background(Theme.windowBackground)
    }
}

private struct CategoryRow: View {
    let result: CategoryResult
    @EnvironmentObject var scanner: ScanEngine

    private var share: Double {
        guard scanner.totalFoundBytes > 0 else { return 0 }
        return Double(result.totalSize) / Double(scanner.totalFoundBytes)
    }

    var body: some View {
        HStack(spacing: 14) {
            Toggle("", isOn: Binding(
                get: { result.enabled },
                set: { _ in scanner.toggle(result.category) }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()
            .disabled(result.items.isEmpty || result.category == .languageFiles)

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Theme.cardElevated)
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: result.category.symbol)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(result.enabled ? Theme.gold : Theme.textTertiary)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("\(result.category.title): \(FileSizer.format(result.totalSize))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(result.items.isEmpty ? Theme.textTertiary : Theme.textPrimary)
                Text(result.items.isEmpty ? "Nothing found — already clean" : result.category.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.cardElevated)
                    Capsule()
                        .fill(result.enabled ? Theme.gold : Theme.goldDim)
                        .frame(width: max(4, geo.size.width * share))
                }
            }
            .frame(width: 140, height: 6)

            Text("\(Int(share * 100))%")
                .font(.system(size: 12, weight: .medium).monospacedDigit())
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 38, alignment: .trailing)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .opacity(result.items.isEmpty ? 0.55 : 1)
    }
}
