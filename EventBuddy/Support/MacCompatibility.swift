import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct EventBuddyDebouncedSearchField: View {
    @Binding var text: String
    let prompt: String
    let cornerRadius: CGFloat
    var autocorrectionDisabled: Bool = false

    @State private var draftText = ""

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField(prompt, text: $draftText)
                .textFieldStyle(.plain)
                .font(.body)
                .autocorrectionDisabled(autocorrectionDisabled)

            if !draftText.isEmpty {
                Button {
                    draftText = ""
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .eventBuddySearchFieldChrome(cornerRadius: cornerRadius)
        .onAppear {
            draftText = text
        }
        .onChange(of: text) { _, newValue in
            if newValue != draftText {
                draftText = newValue
            }
        }
        .task(id: draftText) {
            await applyDraftTextAfterDelay(draftText)
        }
    }

    private func applyDraftTextAfterDelay(_ query: String) async {
        do {
            try await Task.sleep(for: .milliseconds(250))
        } catch {
            return
        }

        if text != query {
            text = query
        }
    }
}

struct EventBuddyDebouncedSearchable<Content: View>: View {
    @Binding var text: String
    let prompt: String
    @ViewBuilder let content: Content

    @State private var draftText = ""

    var body: some View {
        content
            .searchable(text: $draftText, placement: .toolbar, prompt: Text(prompt))
            .onAppear {
                draftText = text
            }
            .onChange(of: text) { _, newValue in
                if newValue != draftText {
                    draftText = newValue
                }
            }
            .task(id: draftText) {
                await applyDraftTextAfterDelay(draftText)
            }
    }

    private func applyDraftTextAfterDelay(_ query: String) async {
        do {
            try await Task.sleep(for: .milliseconds(250))
        } catch {
            return
        }

        if text != query {
            text = query
        }
    }
}

extension View {
    @ViewBuilder
    func eventBuddyInlineNavigationTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    func eventBuddyInsetGroupedListStyle() -> some View {
        #if os(iOS)
        listStyle(.insetGrouped)
        #else
        listStyle(.inset)
        #endif
    }

    @ViewBuilder
    func eventBuddyPopupFormStyle() -> some View {
        #if os(macOS)
        self
            .formStyle(.grouped)
            .controlSize(.regular)
        #else
        self
        #endif
    }

    @ViewBuilder
    func eventBuddyPopupFormLayout(width: CGFloat = 560, minHeight: CGFloat = 460, maxHeight: CGFloat = 720) -> some View {
        #if os(macOS)
        self
            .frame(
                minWidth: width,
                idealWidth: width,
                maxWidth: width,
                minHeight: minHeight,
                idealHeight: minHeight,
                maxHeight: maxHeight
            )
        #else
        self
        #endif
    }

    @ViewBuilder
    func eventBuddyPopupPrimaryAction() -> some View {
        #if os(macOS)
        self
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
        #else
        self
        #endif
    }

    @ViewBuilder
    func eventBuddyPopupCancelAction() -> some View {
        #if os(macOS)
        self
            .keyboardShortcut(.cancelAction)
        #else
        self
        #endif
    }

    @ViewBuilder
    func eventBuddySearchFieldChrome(cornerRadius: CGFloat = 20) -> some View {
        #if os(visionOS)
        self
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            )
        #else
        self
            .padding(10)
            .background(Color.eventBuddySystemGray6)
            .cornerRadius(cornerRadius)
        #endif
    }

    @ViewBuilder
    func eventBuddyFilterChip(isSelected: Bool, tint: Color = .blue, selectedFill: Color? = nil) -> some View {
        #if os(visionOS)
        self
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(
                Capsule()
                    .fill(isSelected ? (selectedFill ?? tint.opacity(0.22)) : Color.white.opacity(0.08))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? tint.opacity(0.5) : Color.white.opacity(0.14), lineWidth: 1)
            )
        #else
        self
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                Capsule()
                    .fill(isSelected ? (selectedFill ?? Color.eventBuddySystemGray5) : Color.eventBuddySystemGray6)
            )
        #endif
    }

    @ViewBuilder
    func eventBuddySettingsListChrome() -> some View {
        #if os(visionOS)
        self
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.eventBuddySystemBackground)
        #else
        self
        #endif
    }
}

extension Color {
    static var eventBuddySystemBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(.background)
        #endif
    }

    static var eventBuddySystemGray6: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemGray6)
        #elseif canImport(AppKit)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(.secondary.opacity(0.1))
        #endif
    }

    static var eventBuddySystemGray5: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemGray5)
        #elseif canImport(AppKit)
        Color(nsColor: .selectedControlColor)
        #else
        Color(.secondary.opacity(0.2))
        #endif
    }
}

#if os(macOS)
enum UIKeyboardType {
    case emailAddress
    case phonePad
    case URL
}

enum UITextContentType {
    case emailAddress
}

enum UITextAutocapitalizationType {
    case none
}

enum TextInputAutocapitalization {
    case words
    case never
}

extension View {
    func keyboardType(_ keyboardType: UIKeyboardType) -> some View {
        self
    }

    func textContentType(_ textContentType: UITextContentType) -> some View {
        self
    }

    func textInputAutocapitalization(_ autocapitalization: TextInputAutocapitalization) -> some View {
        self
    }

    func autocapitalization(_ autocapitalization: UITextAutocapitalizationType) -> some View {
        self
    }
}
#endif
