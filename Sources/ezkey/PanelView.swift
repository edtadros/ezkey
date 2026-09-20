import AppKit
import EZKeyCore
import SwiftUI

struct PanelView: View {
    @Bindable var model: PanelModel
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case service
        case account
        case secret
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Mode", selection: $model.mode) {
                ForEach(PanelMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Mode")
            .disabled(model.isWorking)

            labeledField("Name", text: $model.service, prompt: "edwardtadros-ai-gateway-token", field: .service)
            labeledField("Account", text: $model.account, prompt: "edward", field: .account)

            if model.mode == .save {
                saveSection
            } else {
                retrieveSection
            }

            statusLine

            Divider()

            HStack {
                Button("License") {
                    openLicense()
                }
                .help("Open the license and disclaimer")
                Spacer()
                Button("Quit ezkey") {
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
                .help("Quit ezkey")
            }
            Text("Provided as-is. No warranty.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(width: 340)
        .onAppear {
            model.panelDidOpen()
            focusedField = .service
        }
        .onDisappear {
            model.panelDidClose()
        }
        .background(
            PanelVisibilityObserver(
                onOpen: { model.panelDidOpen() },
                onClose: { model.panelDidClose() }
            )
        )
    }

    private var saveSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Secret")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                SecureField("Secret", text: $model.secretToSave)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .secret)
                    .disabled(model.isWorking)
                    .accessibilityLabel("Secret")
                    .onSubmit {
                        Task { await primarySaveAction() }
                    }
            }

            HStack {
                if model.status == .needsUpdate {
                    Button("Update") {
                        Task { await model.update() }
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(model.isWorking)
                    .accessibilityHint("Replace the existing Keychain entry")
                } else {
                    Button("Save") {
                        Task { await model.save() }
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(model.isWorking)
                    .accessibilityHint("Save a new Keychain entry")
                }
            }
        }
    }

    private var retrieveSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("Retrieve") {
                Task { await model.retrieve() }
            }
            .keyboardShortcut(.defaultAction)
            .disabled(model.isWorking)
            .accessibilityHint("Search by part of the Keychain name, or look up an exact pair")

            if !model.matches.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Matching entries")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(model.matches) { match in
                                Button {
                                    Task { await model.selectMatch(match) }
                                } label: {
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(match.service)
                                            .font(.body)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text(match.account)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 6)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                                .accessibilityLabel("\(match.service), account \(match.account)")
                                .disabled(model.isWorking)
                            }
                        }
                    }
                    .frame(maxHeight: 160)
                }
            }

            if model.retrievedSecret != nil {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Secret")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Group {
                        if model.isRevealed, let secret = model.retrievedSecret {
                            Text(secret)
                                .font(.body.monospaced())
                                .textSelection(.enabled)
                                .lineLimit(6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(6)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                        } else {
                            Text("••••••••")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(6)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .accessibilityLabel("Retrieved secret")
                    .accessibilityValue(model.isRevealed ? "visible" : "hidden")
                }

                HStack {
                    Button(model.isRevealed ? "Hide" : "Reveal") {
                        model.toggleReveal()
                    }
                    .accessibilityLabel(model.isRevealed ? "Hide secret" : "Reveal secret")

                    Button("Copy") {
                        model.copyRetrieved()
                    }
                    .accessibilityHint("Copy the secret, then clear the clipboard after 30 seconds if unchanged")
                }
            }
        }
    }

    private var statusLine: some View {
        Text(model.status.message.isEmpty ? " " : model.status.message)
            .font(.callout)
            .foregroundStyle(model.status.isError ? Color.red : Color.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: 18, alignment: .leading)
            .accessibilityLabel("Status")
            .accessibilityValue(model.status.message)
    }

    private func labeledField(
        _ title: String,
        text: Binding<String>,
        prompt: String,
        field: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(prompt, text: text)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: field)
                .disabled(model.isWorking)
                .accessibilityLabel(title)
                .onSubmit {
                    Task { await primarySaveAction() }
                }
        }
    }

    private func openLicense() {
        if let url = Bundle.main.url(forResource: "LICENSE", withExtension: nil) {
            NSWorkspace.shared.open(url)
        }
    }

    private func primarySaveAction() async {
        if model.mode == .save {
            if model.status == .needsUpdate {
                await model.update()
            } else {
                await model.save()
            }
        } else {
            await model.retrieve()
        }
    }
}

struct PanelVisibilityObserver: NSViewRepresentable {
    var onOpen: () -> Void
    var onClose: () -> Void

    func makeNSView(context: Context) -> Inner {
        let view = Inner()
        view.onOpen = onOpen
        view.onClose = onClose
        return view
    }

    func updateNSView(_ nsView: Inner, context: Context) {
        nsView.onOpen = onOpen
        nsView.onClose = onClose
    }

    final class Inner: NSView {
        var onOpen: (() -> Void)?
        var onClose: (() -> Void)?
        private var observation: NSKeyValueObservation?
        private var wasVisible = false

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            observation = nil
            guard let window else { return }
            observation = window.observe(\.isVisible, options: [.new, .initial]) { [weak self] window, _ in
                DispatchQueue.main.async {
                    self?.handle(visible: window.isVisible)
                }
            }
        }

        private func handle(visible: Bool) {
            guard visible != wasVisible else { return }
            wasVisible = visible
            if visible {
                onOpen?()
            } else {
                onClose?()
            }
        }
    }
}
