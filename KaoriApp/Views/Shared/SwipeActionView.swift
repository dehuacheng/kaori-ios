import SwiftUI

/// Wraps content with a swipe-left-to-reveal action button.
/// Works in ScrollView (unlike .swipeActions which requires List).
struct SwipeActionView<Content: View>: View {
    let icon: String
    let color: Color
    let action: () -> Void
    @ViewBuilder let content: Content

    @State private var offset: CGFloat = 0
    private let buttonWidth: CGFloat = 72

    var body: some View {
        ZStack(alignment: .trailing) {
            // Revealed button behind the card
            Button {
                withAnimation(.spring(duration: 0.3)) { offset = 0 }
                action()
            } label: {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: buttonWidth, height: .infinity)
                    .frame(maxHeight: .infinity)
            }
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(offset < -10 ? 1 : 0)

            // Main content
            content
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 15)
                        .onChanged { value in
                            let dx = value.translation.width
                            if dx < 0 {
                                // Swipe left — rubber-band past button width
                                offset = max(dx, -buttonWidth * 1.5)
                            } else if offset < 0 {
                                // Swipe right to close
                                offset = min(0, offset + dx)
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring(duration: 0.3)) {
                                if value.translation.width < -40 {
                                    offset = -buttonWidth
                                } else {
                                    offset = 0
                                }
                            }
                        }
                )
        }
        .clipped()
    }
}
