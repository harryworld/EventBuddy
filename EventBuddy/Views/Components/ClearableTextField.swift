import SwiftUI

struct ClearableTextField: View {
    let title: String
    @Binding var text: String
    var axis: Axis?

    init(_ title: String, text: Binding<String>, axis: Axis? = nil) {
        self.title = title
        self._text = text
        self.axis = axis
    }

    var body: some View {
        textField
            .padding(.trailing, text.isEmpty ? 0 : 28)
            .overlay(alignment: .trailing) {
                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear \(title)")
                    .accessibilityHint("Clears the \(title.lowercased()) field")
                }
            }
    }

    @ViewBuilder
    private var textField: some View {
        if let axis {
            TextField(title, text: $text, axis: axis)
        } else {
            TextField(title, text: $text)
        }
    }
}
