import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("iOrganize")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            Text("Free and open source")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            Text("All Auto-Flow rules, scheduled runs, Smart Sanitize scans, and automation actions are available without a license or account.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Your files and activity stay on this Mac. No account or cloud service is required.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Link("View source on GitHub", destination: URL(string: "https://github.com/hikaribrandan3-code/iorganize/tree/main/macos-source")!)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.gold)

            Text("iOrganize v1.0.0")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
        }
        .padding(28)
        .padding(.top, 16)
        .frame(maxWidth: 860, alignment: .leading)
    }
}
