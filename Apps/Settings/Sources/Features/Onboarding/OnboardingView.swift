import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var state
    private let onDismiss: () -> Void

    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Set up FinderActions")
                            .font(.title2.weight(.semibold))
                        Text("Two quick system settings make Finder actions available across protected folders.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("1. Allow access to protected folders") {
                    FullDiskAccessGuideView()
                }

                Section("2. Enable the Finder extension") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Open Extensions, enable FinderActions under Added Extensions, then return here.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Button("Open Extension Settings") { state.openExtensionSettings() }
                    }
                    .padding(.vertical, 2)
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Button("Skip for Now", action: finish)
                Spacer()
                Button("Finish Setup", action: finish)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(width: 540, height: 540)
    }

    private func finish() {
        state.completeOnboarding()
        onDismiss()
    }
}
