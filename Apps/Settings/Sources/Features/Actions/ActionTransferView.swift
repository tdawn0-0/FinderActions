import SwiftUI
import AppKit
import UniformTypeIdentifiers
import FinderActionsCore

struct ActionTransferView: View {
    let action: ActionDefinition?
    let store: ManifestStore
    let onImport: (PortableActionPackage) throws -> Void

    private struct ImportPreview: Identifiable {
        let id = UUID()
        let package: PortableActionPackage
    }

    @State private var preview: ImportPreview?
    @State private var showExport = false
    @State private var dependencies = ""
    @State private var error: String?

    var body: some View {
        Menu {
            Button {
                chooseImport()
            } label: {
                Label("Import Package…", systemImage: "square.and.arrow.down")
            }
            Button {
                dependencies = ""
                showExport = true
            } label: {
                Label("Export Package…", systemImage: "square.and.arrow.up")
            }
            .disabled(action == nil)
        } label: {
            Label("Package", systemImage: "shippingbox")
        }
        .accessibilityIdentifier(SettingsAccessibilityID.actionsTransferMenu)
        .dropDestination(for: URL.self) { urls, _ in
            guard urls.count == 1, let url = urls.first else { return false }
            load(url)
            return true
        }
        .sheet(item: $preview) { item in
            ActionImportPreview(package: item.package) {
                try onImport(item.package)
                preview = nil
            }
        }
        .sheet(isPresented: $showExport) {
            exportSheet
        }
        .alert("Package Error", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK") { error = nil }
        } message: {
            Text(error ?? "")
        }
    }

    private var exportSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let action {
                HStack(spacing: 10) {
                    ActionIconTile(symbol: action.icon?.sfSymbol, size: 32)
                    Text(action.name)
                        .font(.headline)
                }
            }

            LabeledContent("Requirements") {
                TextField("Requirements", text: $dependencies, prompt: Text(verbatim: "ffmpeg, jq"))
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Button("Cancel") { showExport = false }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Export…") { export() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 400)
    }

    private func chooseImport() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.data]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        load(url)
    }

    private func load(_ url: URL) {
        do {
            preview = ImportPreview(package: try PortableActionPackage.read(from: url))
        } catch {
            self.error = String(localized: String.LocalizationValue(error.localizedDescription))
        }
    }

    private func export() {
        guard let action else { return }
        do {
            let data = try PortableActionPackage.export(action: action, store: store, dependencies: dependencies).encoded()
            let panel = NSSavePanel()
            let baseName = action.name.trimmingCharacters(in: .whitespacesAndNewlines)
            panel.nameFieldStringValue = baseName.isEmpty ? "Action.faaction" : "\(baseName).faaction"
            panel.allowedContentTypes = [UTType(filenameExtension: "faaction") ?? .data]
            panel.allowsOtherFileTypes = true
            guard panel.runModal() == .OK, let url = panel.url else { return }
            try data.write(to: url, options: .atomic)
            showExport = false
        } catch {
            self.error = String(localized: String.LocalizationValue(error.localizedDescription))
        }
    }
}

private struct ActionImportPreview: View {
    @Environment(\.dismiss) private var dismiss
    let package: PortableActionPackage
    let onImport: () throws -> Void
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ActionIconTile(symbol: package.action.icon?.sfSymbol, isActive: false, size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(package.action.name)
                        .font(.headline)
                    Text(package.action.type.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("Disabled")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.quaternary, in: Capsule())
            }

            if !package.dependencies.isEmpty {
                LabeledContent("Requirements", value: package.dependencies)
                    .font(.callout)
            }

            if let application = package.action.application, !application.bundleId.isEmpty {
                LabeledContent("Application") {
                    Text(application.bundleId)
                        .font(.callout.monospaced())
                }
            }

            if !package.scriptPreviews.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(package.scriptPreviews.enumerated()), id: \.offset) { _, item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                Text(item.source)
                                    .font(.callout.monospaced())
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(8)
                                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                            }
                        }
                    }
                }
                .frame(minHeight: 160, maxHeight: 340)
            }

            if let error {
                Text(error)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Import") {
                    do {
                        try onImport()
                    } catch {
                        self.error = String(localized: String.LocalizationValue(error.localizedDescription))
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 520)
    }
}
