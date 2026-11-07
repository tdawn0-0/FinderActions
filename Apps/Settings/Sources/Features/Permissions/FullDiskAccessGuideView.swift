import SwiftUI

struct FullDiskAccessGuideView: View {
    var body: some View {
        let installed = FullDiskAccessSettings.isInstalledInApplications
        let appPath = FullDiskAccessSettings.applicationURL.path

        LabeledContent("Location") {
            HStack(spacing: 8) {
                Image(systemName: installed ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(installed ? .green : .orange)
                Text(installed ? "/Applications" : appPath)
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(appPath)
                Button("Show in Finder") { FullDiskAccessSettings.revealApplication() }
                    .controlSize(.small)
            }
        }

        LabeledContent("System Settings") {
            Button("Open Full Disk Access…") { FullDiskAccessSettings.openSystemSettings() }
        }
    }
}
