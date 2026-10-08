import SwiftUI

/// Install-location status plus the manual Full Disk Access steps. Rendered as
/// one block so it can sit in a Form section on both the Permissions page and
/// in onboarding.
struct FullDiskAccessGuideView: View {
    var body: some View {
        let installed = FullDiskAccessSettings.isInstalledInApplications

        VStack(alignment: .leading, spacing: 12) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(installed
                         ? "FinderActions is installed in /Applications"
                         : "Recommended: Move FinderActions to /Applications")
                    Text(installed
                         ? "Ready to grant permissions stably."
                         : "Running from Downloads or build folders can invalidate permissions on update.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: installed ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(installed ? .green : .orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("1. Open Full Disk Access in macOS System Settings.")
                Text("2. Click + and select FinderActions.app, or drag the app into the list.")
                Text("3. Turn FinderActions on.")
            }
            .font(.callout)
            .foregroundStyle(.secondary)

            HStack {
                Button("Open Full Disk Access") { FullDiskAccessSettings.openSystemSettings() }
                Button("Show in Finder") { FullDiskAccessSettings.revealApplication() }
            }
        }
        .padding(.vertical, 2)
    }
}
