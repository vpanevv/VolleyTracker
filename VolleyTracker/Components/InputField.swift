import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct InputField: View {
    let title: String
    let prompt: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var submitLabel: SubmitLabel = .next
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.88))

            Group {
                if isSecure {
                    SecureField(prompt, text: $text)
                } else {
                    TextField(prompt, text: $text)
                }
            }
            .textContentType(textContentType)
            .keyboardType(keyboardType)
            .submitLabel(submitLabel)
            .autocorrectionDisabled()
            .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            }
        }
    }
}
