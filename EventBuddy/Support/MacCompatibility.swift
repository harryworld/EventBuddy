import SwiftUI

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
}

extension Color {
    static var eventBuddySystemBackground: Color {
        #if os(iOS)
        Color(uiColor: .systemBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }

    static var eventBuddySystemGray6: Color {
        #if os(iOS)
        Color(uiColor: .systemGray6)
        #else
        Color(nsColor: .controlBackgroundColor)
        #endif
    }

    static var eventBuddySystemGray5: Color {
        #if os(iOS)
        Color(uiColor: .systemGray5)
        #else
        Color(nsColor: .selectedControlColor)
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
