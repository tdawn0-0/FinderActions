import SwiftUI
import AppKit
import UniformTypeIdentifiers
import FinderActionsCore

/// Place in the Actions toolbar. A dropped package opens the same preview as the chooser.
struct ActionTransferView: View {
    let action: ActionDefinition?
    let store: ManifestStore
    let onImport: (PortableActionPackage) throws -> Void
    @State private var preview: PortableActionPackage?
    @State private var showPreview = false
    @State private var showExport = false
    @State private var dependencies = ""
    @State private var error: String?

    var body: some View {
        HStack {
            Button("Import Action…", systemImage: "square.and.arrow.down") { chooseImport() }
            Button("Export Action…", systemImage: "square.and.arrow.up") { showExport = true }
                .disabled(action == nil)
        }
        .help("Drop an .faaction file here to preview it before importing.")
        .dropDestination(for: URL.self) { urls, _ in
            guard urls.count == 1, let url = urls.first else { return false }
            load(url)
            return true
        }
        .sheet(isPresented: $showPreview) {
            if let preview {
                ActionImportPreview(package: preview) {
                    try onImport(preview)
                    showPreview = false
                }
            }
        }
        .sheet(isPresented: $showExport) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Export Action").font(.title2)
                Text("Describe required command-line tools or applications. The package includes this action and its scripts; other files are not included.")
                TextEditor(text: $dependencies)
                    .frame(minHeight: 100)
                    .border(.quaternary)
                HStack {
                    Button("Cancel") { showExport = false }
                    Spacer()
                    Button("Save Package…") { export() }
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding(24)
            .frame(width: 480)
        }
        .alert("Action Package", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK") { error = nil }
        } message: { Text(error ?? "") }
    }

    private func chooseImport() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        // Unknown custom extensions still conform to data; the codec validates content.
        panel.allowedContentTypes = [.data]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        load(url)
    }

    private func load(_ url: URL) {
        do {
            preview = try PortableActionPackage.read(from: url)
            showPreview = true
        } catch { self.error = error.localizedDescription }
    }

    private func export() {
        guard let action else { return }
        do {
            let data = try PortableActionPackage.export(action: action, store: store, dependencies: dependencies).encoded()
            let panel = NSSavePanel()
            panel.nameFieldStringValue = "Action.faaction"
            panel.allowedContentTypes = [.data]
            panel.allowsOtherFileTypes = true
            guard panel.runModal() == .OK, let url = panel.url else { return }
            try data.write(to: url, options: .atomic)
            showExport = false
        } catch { self.error = error.localizedDescription }
    }
}

private struct ActionImportPreview: View {
    @Environment(\.dismiss) private var dismiss
    let package: PortableActionPackage
    let onImport: () throws -> Void
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preview Action Import").font(.title2)
            Text(package.action.name).font(.headline)
            Text("Imported actions start disabled. Existing actions are kept; conflicting names receive a numbered suffix and every import receives a new identifier.")
                .foregroundStyle(.secondary)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Dependencies").font(.headline)
                    Text(package.dependencies.isEmpty ? String(localized: "No dependencies declared. Review the script before enabling it.") : package.dependencies)
                    if let application = package.action.application {
                        Text(application.bundleId).font(.body.monospaced())
                    }
                    ForEach(Array(package.scriptPreviews.enumerated()), id: \.offset) { _, preview in
                        Text(preview.name).font(.headline)
                        Text(preview.source)
                            .font(.body.monospaced())
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 200, maxHeight: 400)
            if let error { Text(error).foregroundStyle(.red).textSelection(.enabled) }
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Import Disabled Action") {
                    do { try onImport() } catch { self.error = error.localizedDescription }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 560)
    }
}
