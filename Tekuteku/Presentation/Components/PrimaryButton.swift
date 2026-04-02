import SwiftUI

struct PrimaryButton: View {
    enum Variant {
        case primary
        case outline
        case cancel
        
        fileprivate var textColor: Color {
            switch self {
            case .primary, .cancel:
                return Color.white
            case .outline:
                return Color.navy
            }
        }
        
        fileprivate var backgroundColor: Color {
            switch self {
            case .primary:
                return Color.navy
            case .outline:
                return Color.white
            case .cancel:
                return Color.red
            }
        }
    }
    
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
                .foregroundStyle(variant.textColor)
                .background(variant.backgroundColor)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(variant.textColor), lineWidth: 1.0)
                )
        }
        .padding(.horizontal, 28)
    }
}
