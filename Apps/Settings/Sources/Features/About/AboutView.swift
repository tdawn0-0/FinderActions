import SwiftUI

struct AboutView: View {
    private static let repositoryURL = URL(string: "https://github.com/tdawn0-0/FinderActions")!

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "—"
        guard let build = info?["CFBundleVersion"] as? String else { return short }
        return "\(short) (\(build))"
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: FullDiskAccessSettings.applicationURL.path))
                .resizable()
                .frame(width: 96, height: 96)
                .accessibilityHidden(true)

            VStack(spacing: 4) {
                Text("FinderActions")
                    .font(.title.weight(.semibold))
                Text("Version \(version)")
                    .foregroundStyle(.secondary)
            }

            Text("Fast, non-sandboxed Host + lightweight FinderSync extension for custom context menu actions.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 380)

            HStack(spacing: 16) {
                Link("GitHub Repository", destination: Self.repositoryURL)
                Text("MIT License")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("About")
    }
}
