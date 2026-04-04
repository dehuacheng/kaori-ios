import SwiftUI

struct PostCardModule: CardModule {
    let cardType = "post"
    let displayNameKey = "card.post"
    let iconName = "note.text"
    let accentColor = Color.purple
    let supportsManualCreation = true
    let hasFeedDetailView = true
    let hasDataListView = true
    let presentationStyle = CardPresentationStyle.sheet

    @MainActor
    func feedCardView(item: FeedItem, displayTime: String?) -> AnyView {
        guard let post = item.payload as? Post else { return AnyView(EmptyView()) }
        return AnyView(PostFeedCard(post: post, displayTime: displayTime))
    }

    @MainActor
    func feedDetailView(item: FeedItem) -> AnyView? {
        guard let post = item.payload as? Post else { return nil }
        return AnyView(PostDetailView(post: post))
    }

    @MainActor
    func createView(onDismiss: @escaping () -> Void) -> AnyView? {
        AnyView(PostCreateView())
    }

    @MainActor
    func dataListView() -> AnyView? {
        AnyView(PostListView())
    }
}
