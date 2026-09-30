import SwiftUI

/// Tab 2 — Auto-Flow: Hazel-style rule list + activity log.
struct AutoFlowView: View {
    @EnvironmentObject var engine: RuleEngine
    @EnvironmentObject var log: ActivityLog
    @State private var editingRule: AutoRule?
    @State private var showingEditor = false

    var body: some View {
        VStack(spacing: 16) {
            statusLine

            ScrollView {
                VStack(spacing: 14) {
                    ForEach(Array(engine.rules.enumerated()), id: \.element.id) { index, rule in
                        RuleRow(index: index + 1, rule: rule) {
                            editingRule = rule
                            showingEditor = true
                        }
                    }
                    if engine.rules.isEmpty {
                        emptyState
                    }
                }
            }

            Spacer(minLength: 0)

            HStack(alignment: .bottom, spacing: 20) {
                newRuleButton
                Spacer()
                activityCard
            }
        }
        .padding(28)
        .sheet(isPresented: $showingEditor) {
            RuleEditorView(rule: editingRule) { saved in
                engine.upsert(saved)
            }
            .environmentObject(engine)
        }
    }

    private var statusLine: some View {
        HStack {
            if engine.paused {
                Label("Auto-Flow is paused", systemImage: "pause.circle.fill")
                    .foregroundStyle(Theme.danger)
                Button("Resume") { engine.paused = false }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.goldSoft)
                    .font(.system(size: 12, weight: .semibold))
            } else {
                Spacer()
                Text("Rules are running automatically in the background")
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .font(.system(size: 12))
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "wand.and.rays")
                .font(.system(size: 34))
                .foregroundStyle(Theme.goldDim)
            Text("No rules yet")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Create a rule and iOrganize will keep your folders tidy for you.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var newRuleButton: some View {
        Button {
            editingRule = nil
            showingEditor = true
        } label: {
            Label("New Rule", systemImage: "plus")
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(Theme.gold, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .foregroundStyle(Color.black.opacity(0.85))
        }
        .buttonStyle(.plain)
    }

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Activity")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.textPrimary)

            if log.entries.isEmpty {
                Text("Nothing automated yet")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(log.entries.prefix(3)) { entry in
                        HStack(spacing: 5) {
                            Text(entry.message)
                                .foregroundStyle(Theme.textSecondary)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            Text(relative(entry.date))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .font(.system(size: 12))
                    }
                }
            }
        }
        .frame(maxWidth: 320, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.cardElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Theme.cardStroke, lineWidth: 1)
                )
        )
    }

    private func relative(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Rule row

private struct RuleRow: View {
    let index: Int
    let rule: AutoRule
    let onEdit: () -> Void
    @EnvironmentObject var engine: RuleEngine

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(index).")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 8) {
                Text(rule.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)

                HStack(alignment: .top, spacing: 32) {
                    labeledColumn("Condition:", lines: conditionLines)
                    labeledColumn("Action:", lines: [rule.action.summary])
                    labeledColumn("Folder:", lines: [rule.folderDisplayName])
                }
            }

            Spacer()

            HStack(spacing: 10) {
                onOffToggle
                iconButton("pencil", action: onEdit)
                iconButton("trash") { engine.delete(rule) }
            }
            .padding(.top, 2)
        }
        .padding(16)
        .card()
        .opacity(rule.enabled ? 1 : 0.6)
    }

    private var conditionLines: [String] {
        var lines = rule.conditions.map(\.summary)
        if rule.conditions.count > 1 && !rule.matchAll {
            lines.append("(any can match)")
        }
        return lines
    }

    private func labeledColumn(_ label: String, lines: [String]) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(label)
                .foregroundStyle(Theme.textTertiary)
            VStack(alignment: .leading, spacing: 3) {
                ForEach(lines, id: \.self) { line in
                    Text(line).foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .font(.system(size: 12))
    }

    private var onOffToggle: some View {
        Button {
            engine.toggle(rule)
        } label: {
            HStack(spacing: 6) {
                if rule.enabled {
                    Text("ON")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.black.opacity(0.8))
                    Circle().fill(.white).frame(width: 14, height: 14)
                } else {
                    Circle().fill(Theme.textSecondary).frame(width: 14, height: 14)
                    Text("OFF")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(.horizontal, 6)
            .frame(height: 22)
            .background(
                Capsule().fill(rule.enabled ? Theme.success : Theme.cardElevated)
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                rule.enabled ? Theme.success.opacity(0.3) : Theme.cardStroke,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func iconButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 28, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Theme.cardElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .strokeBorder(Theme.cardStroke, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}
