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

    func decodeFeedItem(_ item: FeedAPIItem, context: CardFeedDecodingContext) -> FeedItem? {
        guard item.type == cardType, let rawData = item.rawData,
              let post = try? context.decoder.decode(Post.self, from: rawData) else {
            return nil
        }
        return .post(post)
    }

    @MainActor
    func deleteFeedItem(_ item: FeedItem, context: CardDeleteContext) async {
        guard let post = item.payload as? Post else { return }
        let _: PostDeleteResponse? = try? await context.api.delete("/api/post/\(post.id)")
    }
}
