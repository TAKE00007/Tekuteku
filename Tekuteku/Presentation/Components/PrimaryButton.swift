import SwiftUI

struct PrimaryButton: View {
    enum Variant { case primary, outline }
    
    let title: String
    let variant: Variant
    let action: () -> Void
    
    init(title: String, variant: Variant, action: @escaping () -> Void) {
        self.title = title
        self.variant = variant
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, minHeight:  48)
                .foregroundStyle(variant == .primary ? .white : Color.navy)
                .background(variant == .primary ? Color.navy : .clear)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.navy), lineWidth: 1.0)
                )
        }
        .padding(.horizontal, 28)
    }
}
