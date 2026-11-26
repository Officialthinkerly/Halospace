//
//  SpatialAppContentView.swift
//  HaloSpace V3
//

import PhotosUI
import SwiftUI
import WebKit

struct SpatialAppContentView: View {
    let window: HaloWindowModel

    var body: some View {
        Group {
            if window.applicationID == HaloAppID.browser || HaloAppID.isWebApplication(window.applicationID) {
                SpatialBrowserAppView(window: window)
            } else if window.applicationID == HaloAppID.notes {
                SpatialNotesAppView()
            } else if window.applicationID == HaloAppID.photos {
                SpatialPhotosAppView()
            } else if window.applicationID == HaloAppID.calculator {
                SpatialCalculatorAppView()
            } else if window.applicationID == HaloAppID.settings {
                SpatialInSpaceSettingsView()
            } else {
                SpatialBrowserAppView(window: window)
            }
        }
    }
}

// MARK: - Browser & Web Apps

struct SpatialBrowserAppView: View {
    let window: HaloWindowModel

    @EnvironmentObject private var settings: HaloSettingsModel
    @EnvironmentObject private var windowManager: HaloWindowManager

    @State private var addressText: String = ""
    @State private var currentURL: URL = URL(string: "https://duckduckgo.com")!
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var isLoading = false
    @State private var webViewRef: WKWebView?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Button {
                    webViewRef?.goBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 24, height: 24)
                }
                .disabled(!canGoBack)
                .foregroundStyle(canGoBack ? HaloColor.textPrimary : HaloColor.textTertiary)

                Button {
                    webViewRef?.goForward()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 24, height: 24)
                }
                .disabled(!canGoForward)
                .foregroundStyle(canGoForward ? HaloColor.textPrimary : HaloColor.textTertiary)

                TextField("Search or enter website", text: $addressText)
                    .font(.system(size: 12))
                    .foregroundStyle(HaloColor.textPrimary)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .submitLabel(.go)
                    .onSubmit { navigateToInput() }
                    .padding(.horizontal, 8)
                    .frame(height: 26)
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.white.opacity(0.08)))

                Button {
                    if isLoading {
                        webViewRef?.stopLoading()
                    } else {
                        webViewRef?.reload()
                    }
                } label: {
                    Image(systemName: isLoading ? "xmark" : "arrow.clockwise")
                        .font(.system(size: 11.5, weight: .semibold))
                        .frame(width: 24, height: 24)
                }
                .foregroundStyle(HaloColor.textSecondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.22))

            if isLoading {
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(HaloColor.ice)
                    .frame(height: 2)
            }

            SpatialWebViewRepresentable(
                url: currentURL,
                onStateChange: { url, back, forward, loading, webView in
                    webViewRef = webView
                    canGoBack = back
                    canGoForward = forward
                    isLoading = loading
                    if let url {
                        addressText = url.absoluteString
                        windowManager.updatePayload(window.id, key: "url", value: url.absoluteString)
                    }
                }
            )
        }
        .onAppear {
            if let saved = window.payload["url"], let url = URL(string: saved) {
                currentURL = url
                addressText = saved
            } else {
                let defaultURL = settings.searchEngine.searchURL("") ?? URL(string: "https://duckduckgo.com")!
                let baseHostURL = URL(string: "https://\(defaultURL.host ?? "duckduckgo.com")")!
                currentURL = baseHostURL
                addressText = baseHostURL.absoluteString
            }
        }
    }

    private func navigateToInput() {
        if let resolved = HaloLinkParser.normalizedURL(from: addressText, searchEngine: settings.searchEngine) {
            currentURL = resolved
            webViewRef?.load(URLRequest(url: resolved))
        }
    }
}

private struct SpatialWebViewRepresentable: UIViewRepresentable {
    let url: URL
    let onStateChange: (URL?, Bool, Bool, Bool, WKWebView) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onStateChange: onStateChange)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        let onStateChange: (URL?, Bool, Bool, Bool, WKWebView) -> Void

        init(onStateChange: @escaping (URL?, Bool, Bool, Bool, WKWebView) -> Void) {
            self.onStateChange = onStateChange
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            onStateChange(webView.url, webView.canGoBack, webView.canGoForward, true, webView)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            onStateChange(webView.url, webView.canGoBack, webView.canGoForward, false, webView)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            onStateChange(webView.url, webView.canGoBack, webView.canGoForward, false, webView)
        }
    }
}

// MARK: - Notes App

struct SpatialNotesAppView: View {
    @EnvironmentObject private var notesStore: NotesStore
    @State private var selectedNoteID: UUID?
    @State private var draftBody: String = ""

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack {
                    Text("Notes")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(HaloColor.textSecondary)
                    Spacer()
                    Button {
                        let created = notesStore.createNote(body: "New Note\n")
                        selectNote(created)
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(HaloColor.ice)
                    }
                    .buttonStyle(.plain)
                }
                .padding(8)

                Divider().background(Color.white.opacity(0.08))

                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(notesStore.sortedNotes) { note in
                            Button {
                                selectNote(note)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(note.title)
                                        .font(.system(size: 11.5, weight: .medium))
                                        .foregroundStyle(HaloColor.textPrimary)
                                        .lineLimit(1)
                                    Text(note.preview)
                                        .font(.system(size: 10))
                                        .foregroundStyle(HaloColor.textTertiary)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(7)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(selectedNoteID == note.id ? Color.white.opacity(0.10) : .clear)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                }
            }
            .frame(width: 122)
            .background(Color.black.opacity(0.18))

            Divider().background(Color.white.opacity(0.08))

            if let id = selectedNoteID {
                VStack(spacing: 0) {
                    TextEditor(text: $draftBody)
                        .font(.system(size: 12.5))
                        .foregroundStyle(HaloColor.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .onChange(of: draftBody) { newValue in
                            notesStore.updateNote(id: id, body: newValue)
                        }

                    HStack {
                        Spacer()
                        Button(role: .destructive) {
                            notesStore.deleteNote(id: id)
                            selectedNoteID = notesStore.sortedNotes.first?.id
                            draftBody = notesStore.sortedNotes.first?.body ?? ""
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundStyle(HaloColor.danger)
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                    }
                }
            } else {
                Text("Select or create a note")
                    .font(HaloFont.footnote)
                    .foregroundStyle(HaloColor.textTertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if selectedNoteID == nil, let first = notesStore.sortedNotes.first {
                selectNote(first)
            }
        }
    }

    private func selectNote(_ note: HaloNote) {
        selectedNoteID = note.id
        draftBody = note.body
    }
}

// MARK: - Photos App

struct SpatialPhotosAppView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var loadedImage: Image?

    var body: some View {
        VStack(spacing: 12) {
            if let loadedImage {
                loadedImage
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(10)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 28))
                        .foregroundStyle(HaloColor.violet)
                    Text("Halo Photos")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(HaloColor.textPrimary)
                    Text("Pick a photo from your library to view it in your space.")
                        .font(.system(size: 11))
                        .foregroundStyle(HaloColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
            }

            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label(loadedImage == nil ? "Choose Photo" : "Change Photo", systemImage: "photo")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(HaloColor.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
            }
            .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: selectedItem) { item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    loadedImage = Image(uiImage: uiImage)
                }
            }
        }
    }
}

// MARK: - Calculator App

struct SpatialCalculatorAppView: View {
    @EnvironmentObject private var settings: HaloSettingsModel
    @State private var display = "0"
    @State private var storedValue: Double?
    @State private var pendingOp: String?
    @State private var shouldResetDisplay = false

    private let rows: [[String]] = [
        ["C", "±", "%", "÷"],
        ["7", "8", "9", "×"],
        ["4", "5", "6", "−"],
        ["1", "2", "3", "+"],
        ["0", ".", "="]
    ]

    var body: some View {
        VStack(spacing: 6) {
            Text(display)
                .font(.system(size: 28, weight: .light, design: .rounded))
                .foregroundStyle(HaloColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 12)
                .padding(.top, 8)

            ForEach(rows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            HaloHaptics.selection(enabled: settings.hapticsEnabled)
                            handleKey(key)
                        } label: {
                            Text(key)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(isOperator(key) ? HaloColor.ice : HaloColor.textPrimary)
                                .frame(maxWidth: key == "0" ? .infinity : .infinity, maxHeight: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(isOperator(key) ? HaloColor.ice.opacity(0.16) : Color.white.opacity(0.08))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(10)
    }

    private func isOperator(_ key: String) -> Bool {
        ["÷", "×", "−", "+", "="].contains(key)
    }

    private func handleKey(_ key: String) {
        switch key {
        case "C":
            display = "0"
            storedValue = nil
            pendingOp = nil
            shouldResetDisplay = false
        case "±":
            if let val = Double(display), val != 0 {
                display = formatNumber(-val)
            }
        case "%":
            if let val = Double(display) {
                display = formatNumber(val / 100.0)
            }
        case "÷", "×", "−", "+":
            evaluatePending()
            storedValue = Double(display)
            pendingOp = key
            shouldResetDisplay = true
        case "=":
            evaluatePending()
            pendingOp = nil
            shouldResetDisplay = true
        case ".":
            if shouldResetDisplay {
                display = "0."
                shouldResetDisplay = false
            } else if !display.contains(".") {
                display += "."
            }
        default:
            if shouldResetDisplay || display == "0" {
                display = key
                shouldResetDisplay = false
            } else if display.count < 12 {
                display += key
            }
        }
    }

    private func evaluatePending() {
        guard let op = pendingOp, let lhs = storedValue, let rhs = Double(display) else { return }
        let result: Double
        switch op {
        case "+": result = lhs + rhs
        case "−": result = lhs - rhs
        case "×": result = lhs * rhs
        case "÷": result = rhs == 0 ? 0 : lhs / rhs
        default: result = rhs
        }
        display = formatNumber(result)
        storedValue = result
    }

    private func formatNumber(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 && abs(value) < 1e10 {
            return String(Int(value))
        }
        return String(format: "%.6g", value)
    }
}

// MARK: - In-Space Settings App

struct SpatialInSpaceSettingsView: View {
    @EnvironmentObject private var settings: HaloSettingsModel
    @EnvironmentObject private var windowManager: HaloWindowManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Hand Tracking", isOn: $settings.handTrackingEnabled)
                    .font(.system(size: 13, weight: .medium))
                    .tint(HaloColor.ice)

                Toggle("Plane Detection", isOn: $settings.planeDetectionEnabled)
                    .font(.system(size: 13, weight: .medium))
                    .tint(HaloColor.ice)

                Toggle("Diagnostics HUD", isOn: $settings.showDiagnosticsOverlay)
                    .font(.system(size: 13, weight: .medium))
                    .tint(HaloColor.ice)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Window Scale (\(String(format: "%.0f%%", settings.windowScale * 100)))")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(HaloColor.textSecondary)
                    Slider(value: $settings.windowScale, in: 0.75...1.25)
                        .tint(HaloColor.ice)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Glass Opacity (\(String(format: "%.0f%%", settings.uiTransparency * 100)))")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(HaloColor.textSecondary)
                    Slider(value: $settings.uiTransparency, in: 0.4...0.95)
                        .tint(HaloColor.ice)
                }

                HStack(spacing: 8) {
                    Button("Tidy Windows") {
                        windowManager.tidyWorkspace()
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.white.opacity(0.10)))

                    Button("Reset Space") {
                        windowManager.resetWorkspace()
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.white.opacity(0.10)))
                }
                .foregroundStyle(HaloColor.textPrimary)
            }
            .padding(14)
        }
    }
}
