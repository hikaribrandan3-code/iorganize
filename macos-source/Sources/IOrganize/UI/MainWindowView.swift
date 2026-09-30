import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case sanitize, autoFlow, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sanitize: return "Smart Sanitize"
        case .autoFlow: return "Auto-Flow"
        case .settings: return "Settings"
        }
    }
}

struct MainWindowView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        VStack(spacing: 0) {
            tabBar
                .padding(.top, 14)
                .padding(.bottom, 4)

            switch app.tab {
            case .sanitize:
                SanitizeView()
                    .environmentObject(app.scanner)
            case .autoFlow:
                AutoFlowView()
                    .environmentObject(app.ruleEngine)
                    .environmentObject(ActivityLog.shared)
            case .settings:
                SettingsView()
            }
        }
        .frame(minWidth: 820, minHeight: 600)
        .background(Theme.windowBackground)
    }

    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    guard app.tab != tab else { return }
                    withAnimation(.easeOut(duration: 0.08)) { app.tab = tab }
                } label: {
                    Text(tab.title)
                        .font(.system(size: 13, weight: app.tab == tab ? .semibold : .regular))
                        .foregroundStyle(app.tab == tab ? Theme.gold : Theme.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(app.tab == tab ? Theme.goldSoft.opacity(0.15) : .clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .strokeBorder(
                                            app.tab == tab ? Theme.gold.opacity(0.3) : Theme.cardStroke,
                                            lineWidth: 1
                                        )
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.sidebarBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Theme.cardStroke, lineWidth: 1)
                )
        )
    }
}
