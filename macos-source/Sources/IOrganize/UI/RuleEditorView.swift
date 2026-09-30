import AppKit
import SwiftUI

/// Sheet-based rule builder: conditions (with AND/OR), one action, schedule.
struct RuleEditorView: View {
    let onSave: (AutoRule) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var ruleID: UUID
    @State private var name: String
    @State private var folder: String
    @State private var matchAll: Bool
    @State private var conditions: [ConditionDraft]
    @State private var actionKind: ActionKind
    @State private var actionParam: String
    @State private var schedule: RuleSchedule
    private let existingEnabled: Bool
    private let existingLastRun: Date?

    init(rule: AutoRule?, onSave: @escaping (AutoRule) -> Void) {
        self.onSave = onSave
        let downloads = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Downloads").path
        _ruleID = State(initialValue: rule?.id ?? UUID())
        _name = State(initialValue: rule?.name ?? "")
        _folder = State(initialValue: rule?.folder ?? downloads)
        _matchAll = State(initialValue: rule?.matchAll ?? true)
        _conditions = State(initialValue: rule.map { $0.conditions.map(ConditionDraft.init) }
            ?? [ConditionDraft(kind: .fileExtension, text: "dmg", number: 7)])
        let draft = ActionDraft(rule?.action)
        _actionKind = State(initialValue: draft.kind)
        _actionParam = State(initialValue: draft.param)
        _schedule = State(initialValue: rule?.schedule ?? .immediate)
        existingEnabled = rule?.enabled ?? true
        existingLastRun = rule?.lastRun
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(name.isEmpty ? "New Rule" : name)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .padding(24)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    nameSection
                    folderSection
                    conditionsSection
                    actionSection
                    scheduleSection
                }
                .padding(2)
                .padding(24)
            }
            .frame(maxHeight: .infinity)

            Divider()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button {
                    onSave(builtRule)
                    dismiss()
                } label: {
                    Text("Save Rule")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(canSave ? Theme.gold : Theme.cardElevated,
                                    in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .foregroundStyle(canSave ? Color.black.opacity(0.85) : Theme.textTertiary)
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
                .keyboardShortcut(.defaultAction)
            }
            .padding(24)
        }
        .frame(width: 560, height: 650)
        .background(Theme.windowBackground)
    }

    private var canSave: Bool {
        !folder.isEmpty && !conditions.isEmpty
            && conditions.allSatisfy(\.isValid)
            && (!actionKind.needsParam || !actionParam.isEmpty)
    }

    private var builtRule: AutoRule {
        let built = conditions.compactMap(\.built)
        var rule = AutoRule(
            id: ruleID,
            name: name.isEmpty ? autoName(built) : name,
            enabled: existingEnabled,
            folder: folder,
            matchAll: matchAll,
            conditions: built,
            action: ActionDraft(kind: actionKind, param: actionParam).built,
            schedule: schedule
        )
        rule.lastRun = existingLastRun
        return rule
    }

    private func autoName(_ conditions: [RuleCondition]) -> String {
        let what = conditions.first?.summary ?? "Files"
        return "\(what) → \(ActionDraft(kind: actionKind, param: actionParam).built.summary)"
    }

    // MARK: Sections

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel("Rule name")
            TextField("Auto-named from condition if left empty", text: $name)
                .textFieldStyle(.roundedBorder)
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private var folderSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel("Watched folder")
            HStack {
                Text(folder)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button("Choose…") { pickFolder($folder) }
            }
            .padding(10)
            .card()
        }
    }

    private var conditionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionLabel("Conditions")
                Spacer()
                if conditions.count > 1 {
                    Picker("", selection: $matchAll) {
                        Text("Match all (AND)").tag(true)
                        Text("Match any (OR)").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 240)
                }
            }
            ForEach($conditions) { $draft in
                HStack(spacing: 8) {
                    Picker("", selection: $draft.kind) {
                        ForEach(ConditionKind.allCases) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                    .frame(width: 170)

                    switch draft.kind.paramStyle {
                    case .text(let placeholder):
                        TextField(placeholder, text: $draft.text)
                            .textFieldStyle(.roundedBorder)
                            .foregroundStyle(Theme.textPrimary)
                    case .number(let unit):
                        TextField("", value: $draft.number, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .foregroundStyle(Theme.textPrimary)
                            .frame(width: 70)
                        Text(unit)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                    case .none:
                        Spacer()
                    }

                    Button {
                        conditions.removeAll { $0.id == draft.id }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .disabled(conditions.count == 1)
                }
            }
            Button {
                conditions.append(ConditionDraft(kind: .nameContains, text: "", number: 7))
            } label: {
                Label("Add condition", systemImage: "plus.circle")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.goldSoft)
            }
            .buttonStyle(.plain)
        }
    }

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel("Action")
            Picker("", selection: $actionKind) {
                ForEach(ActionKind.allCases) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            .frame(width: 250)
            .onChange(of: actionKind) { _, _ in actionParam = "" }

            switch actionKind.paramStyle {
            case .folder:
                HStack {
                    Text(actionParam.isEmpty ? "No folder selected" : actionParam)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("Choose…") { pickFolder($actionParam) }
                }
                .padding(10)
                .card()
            case .pattern:
                TextField("{date} {name}.{ext}", text: $actionParam)
                    .textFieldStyle(.roundedBorder)
                    .foregroundStyle(Theme.textPrimary)
                Text("Variables: {date} {name} {ext}")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
            case .app:
                HStack {
                    Text(actionParam.isEmpty ? "No app selected" : (actionParam as NSString).lastPathComponent)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Button("Choose App…") { pickFile($actionParam, dir: "/Applications", types: ["app"]) }
                }
                .padding(10)
                .card()
            case .script:
                HStack {
                    Text(actionParam.isEmpty ? "No script selected" : (actionParam as NSString).lastPathComponent)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Button("Choose Script…") { pickFile($actionParam, dir: nil, types: nil) }
                }
                .padding(10)
                .card()
            case .none:
                if actionKind == .deletePermanently {
                    Label("Permanent — files skip the Trash and cannot be recovered.",
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.danger)
                }
            }
        }
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel("Run")
            Picker("", selection: $schedule) {
                ForEach(RuleSchedule.allCases) { s in
                    Text(s.title).tag(s)
                }
            }
            .frame(width: 300)
        }
    }

    // MARK: Pickers

    private func pickFolder(_ binding: Binding<String>) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            binding.wrappedValue = url.path
        }
    }

    private func pickFile(_ binding: Binding<String>, dir: String?, types: [String]?) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if let dir { panel.directoryURL = URL(fileURLWithPath: dir) }
        if panel.runModal() == .OK, let url = panel.url {
            if let types, !types.contains(url.pathExtension.lowercased()) { return }
            binding.wrappedValue = url.path
        }
    }
}

// MARK: - Drafts (editor-side mutable mirrors of the enum models)

enum ConditionKind: String, CaseIterable, Identifiable {
    case fileExtension, nameContains, olderThanDays, largerThanMB, isScreenshot

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fileExtension: return "File type is"
        case .nameContains: return "Name contains"
        case .olderThanDays: return "Older than"
        case .largerThanMB: return "Larger than"
        case .isScreenshot: return "Is a screenshot"
        }
    }

    enum ParamStyle {
        case text(String), number(String), none
    }

    var paramStyle: ParamStyle {
        switch self {
        case .fileExtension: return .text("dmg")
        case .nameContains: return .text("Screenshot")
        case .olderThanDays: return .number("days")
        case .largerThanMB: return .number("MB")
        case .isScreenshot: return .none
        }
    }
}

struct ConditionDraft: Identifiable {
    let id = UUID()
    var kind: ConditionKind
    var text: String
    var number: Int

    init(kind: ConditionKind, text: String, number: Int) {
        self.kind = kind
        self.text = text
        self.number = number
    }

    init(_ condition: RuleCondition) {
        switch condition {
        case .fileExtension(let ext): self.init(kind: .fileExtension, text: ext, number: 7)
        case .nameContains(let t): self.init(kind: .nameContains, text: t, number: 7)
        case .olderThanDays(let d): self.init(kind: .olderThanDays, text: "", number: d)
        case .largerThanMB(let mb): self.init(kind: .largerThanMB, text: "", number: mb)
        case .isScreenshot: self.init(kind: .isScreenshot, text: "", number: 7)
        }
    }

    var isValid: Bool {
        switch kind.paramStyle {
        case .text: return !text.trimmingCharacters(in: .whitespaces).isEmpty
        case .number: return number > 0
        case .none: return true
        }
    }

    var built: RuleCondition? {
        guard isValid else { return nil }
        switch kind {
        case .fileExtension: return .fileExtension(text.trimmingCharacters(in: .whitespaces))
        case .nameContains: return .nameContains(text)
        case .olderThanDays: return .olderThanDays(number)
        case .largerThanMB: return .largerThanMB(number)
        case .isScreenshot: return .isScreenshot
        }
    }
}

enum ActionKind: String, CaseIterable, Identifiable {
    case moveToFolder, rename, compress, moveToTrash, deletePermanently, openWith, runScript

    var id: String { rawValue }

    var title: String {
        switch self {
        case .moveToFolder: return "Move to folder"
        case .rename: return "Rename"
        case .compress: return "Archive (zip)"
        case .moveToTrash: return "Move to Trash"
        case .deletePermanently: return "Delete permanently"
        case .openWith: return "Open with app"
        case .runScript: return "Run script"
        }
    }

    enum ParamStyle { case folder, pattern, app, script, none }

    var paramStyle: ParamStyle {
        switch self {
        case .moveToFolder: return .folder
        case .rename: return .pattern
        case .openWith: return .app
        case .runScript: return .script
        case .compress, .moveToTrash, .deletePermanently: return .none
        }
    }

    var needsParam: Bool {
        switch paramStyle {
        case .none: return false
        default: return true
        }
    }
}

struct ActionDraft {
    var kind: ActionKind
    var param: String

    init(kind: ActionKind, param: String) {
        self.kind = kind
        self.param = param
    }

    init(_ action: RuleAction?) {
        switch action {
        case .moveToFolder(let p): self.init(kind: .moveToFolder, param: p)
        case .rename(let p): self.init(kind: .rename, param: p)
        case .compress: self.init(kind: .compress, param: "")
        case .moveToTrash, .none: self.init(kind: .moveToTrash, param: "")
        case .deletePermanently: self.init(kind: .deletePermanently, param: "")
        case .openWith(let p): self.init(kind: .openWith, param: p)
        case .runScript(let p): self.init(kind: .runScript, param: p)
        }
    }

    var built: RuleAction {
        switch kind {
        case .moveToFolder: return .moveToFolder(param)
        case .rename: return .rename(param)
        case .compress: return .compress
        case .moveToTrash: return .moveToTrash
        case .deletePermanently: return .deletePermanently
        case .openWith: return .openWith(param)
        case .runScript: return .runScript(param)
        }
    }
}
