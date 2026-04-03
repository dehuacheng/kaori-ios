import SwiftUI

/// Apple Health–inspired dark card style for feed items
struct FeedCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

extension View {
    func feedCard() -> some View {
        modifier(FeedCardModifier())
    }
}
