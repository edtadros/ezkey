import AppKit
import EZKeyCore
import SwiftUI

struct PanelView: View {
    @Bindable var model: PanelModel
    @FocusState private var focusedField: Field?
    @State private var opensAtLogin = false
    @State private var loginItemNote = ""

    private enum Field: Hashable {
        case service
        case secret
        case note
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

            labeledField("Name", text: $model.service, prompt: "my-app-api-token", field: .service)

            if model.mode == .save {
                saveSection
            } else {
                retrieveSection
            }

            statusLine

            Divider()

            Toggle(isOn: Binding(
                get: { opensAtLogin },
                set: { newValue in
                    loginItemNote = LoginItem.setEnabled(newValue)
                    opensAtLogin = LoginItem.isEnabled || LoginItem.needsApproval
                }
            )) {
                Text("Open at Login")
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .help(loginItemNote.isEmpty
                ? "Start ezkey when you log in"
                : loginItemNote)
            if !loginItemNote.isEmpty {
                Text(loginItemNote)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

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
            opensAtLogin = LoginItem.isEnabled || LoginItem.needsApproval
            if LoginItem.needsApproval {
                loginItemNote = "Allow ezkey in System Settings → General → Login Items."
            }
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
                        Task { await model.submit() }
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("optional", text: $model.noteToSave, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
                    .focused($focusedField, equals: .note)
                    .disabled(model.isWorking)
                    .accessibilityLabel("Notes")
                    .help("Stored as Keychain Access Comments")
            }

            Button("Save") {
                Task { await model.save() }
            }
            .keyboardShortcut(.defaultAction)
            .disabled(model.isWorking)
            .accessibilityHint("Save a new Keychain entry")
        }
    }

    private var retrieveSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("Retrieve") {
                Task { await model.retrieve() }
            }
            .keyboardShortcut(.defaultAction)
            .disabled(model.isWorking || model.pendingUpdate != nil)
            .accessibilityHint("Search by part of the Keychain name, or look up an exact pair")

            if !model.matches.isEmpty {
                matchPicker
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
                    .modifier(ReadOnlyNudge(model: model))
                }

                HStack {
                    Button(model.isRevealed ? "Hide" : "Reveal") {
                        model.toggleReveal()
                    }
                    .accessibilityLabel(model.isRevealed ? "Hide secret" : "Reveal secret")
                    .accessibilityHint("Shows or hides the current secret and, while Update is open, the new one")

                    Button("Copy") {
                        model.copyRetrieved()
                    }
                    .accessibilityHint("Copy the secret, then clear the clipboard after 30 seconds if unchanged")

                    if model.pendingUpdate == nil {
                        Spacer()
                        Button("Update…") {
                            model.beginUpdate()
                        }
                        .modifier(Highlight(isOn: model.status == .clickUpdateToChange))
                        .disabled(model.isWorking)
                        .accessibilityHint("Replace this secret or its notes")
                    }
                }

                if let note = model.retrievedNote, StoredSecret.normalizedNote(note).isEmpty == false {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(note)
                            .font(.body)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(6)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                            .fixedSize(horizontal: false, vertical: true)
                            .modifier(ReadOnlyNudge(model: model))
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Notes")
                    .accessibilityValue(note)
                }

                if let summary = model.updateSummary {
                    updateSection(summary)
                }
            }
        }
    }

    /// The popover hugs the view's fitting size. A ScrollView with only
    /// maxHeight reports ~0 height, so the picker header showed with no rows.
    private var matchPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Matching entries")
                .font(.caption)
                .foregroundStyle(.secondary)
            if model.matches.count > 6 {
                ScrollView {
                    matchRows
                }
                .frame(height: 180)
            } else {
                matchRows
            }
        }
    }

    private var matchRows: some View {
        VStack(spacing: 6) {
            ForEach(model.matches) { match in
                matchRow(match)
            }
        }
    }

    private func matchRow(_ match: SecretIdentity) -> some View {
        Button {
            Task { await model.selectMatch(match) }
        } label: {
            VStack(alignment: .leading, spacing: 1) {
                Text(match.service)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if match.account != model.currentUser {
                    Text(match.account)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(.separator.opacity(0.7), lineWidth: 1)
        }
        .accessibilityLabel("\(match.service), account \(match.account)")
        .accessibilityHint("Retrieve this Keychain entry")
        .disabled(model.isWorking)
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
                    Task { await model.submit() }
                }
        }
    }

    private func updateSection(_ summary: UpdateSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            Text("Update")
                .font(.headline)
            VStack(alignment: .leading, spacing: 4) {
                Text("New secret")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Group {
                    if model.isRevealed {
                        TextField("Leave empty to keep the current secret", text: newSecret)
                            .font(.body.monospaced())
                    } else {
                        SecureField("Leave empty to keep the current secret", text: newSecret)
                    }
                }
                .textFieldStyle(.roundedBorder)
                .disabled(model.isWorking)
                .accessibilityLabel("New secret")
                .onSubmit { Task { await model.submit() } }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("optional", text: Binding(
                    get: { model.pendingUpdate?.note ?? "" },
                    set: { model.pendingUpdate?.note = $0 }
                ), axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
                .disabled(model.isWorking)
                .accessibilityLabel("New notes")
                .onSubmit { Task { await model.submit() } }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("What changes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(Self.secretChangeText(summary.secret))
                Text(summary.noteChanged
                    ? "Notes: \(Self.quoted(summary.currentNote)) → \(Self.quoted(summary.newNote))"
                    : "Notes: unchanged")
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.callout)
            Text("Replacing is permanent. The old secret cannot be recovered. macOS asks for your login password to allow it.")
                .font(.caption)
                .foregroundStyle(.orange)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Button("Cancel") {
                    model.cancelUpdate()
                }
                .disabled(model.isWorking)
                Spacer()
                Button("Replace", role: .destructive) {
                    Task { await model.replaceRetrieved() }
                }
                .modifier(Highlight(isOn: model.status == .clickReplaceToUpdate))
                .disabled(!summary.hasChanges || model.isWorking)
                .accessibilityHint("Permanently replace this entry after the macOS password prompt")
            }
        }
    }

    /// Reveal and Hide cover the current and the new secret together.
    private var newSecret: Binding<String> {
        Binding(
            get: { model.pendingUpdate?.secret ?? "" },
            set: { model.pendingUpdate?.secret = $0 }
        )
    }

    private static func secretChangeText(_ change: UpdateSummary.SecretChange) -> String {
        switch change {
        case .kept: "Secret: kept"
        case .replaced: "Secret: replaced"
        case .sameAsCurrent: "Secret: same as the current one"
        }
    }

    private static func quoted(_ note: String) -> String {
        note.isEmpty ? "(none)" : "“\(note)”"
    }

    private func openLicense() {
        if let url = Bundle.main.url(forResource: "LICENSE", withExtension: nil) {
            NSWorkspace.shared.open(url)
        }
    }

}

/// The retrieved secret and notes are read-only. Typing into them points at
/// Update… instead of silently doing nothing. Command shortcuts (Copy),
/// Tab and Escape pass through.
private struct ReadOnlyNudge: ViewModifier {
    let model: PanelModel

    func body(content: Content) -> some View {
        content
            .focusable()
            .onKeyPress { press in
                if press.modifiers.contains(.command) || press.key == .tab || press.key == .escape {
                    return .ignored
                }
                model.nudgeTowardUpdate()
                return .handled
            }
    }
}

/// Makes the button the nudge points at stand out.
private struct Highlight: ViewModifier {
    let isOn: Bool

    func body(content: Content) -> some View {
        if isOn {
            content.buttonStyle(.borderedProminent)
        } else {
            content
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
