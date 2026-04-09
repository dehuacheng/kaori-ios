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
    func feedLeadingSwipeContent(item: FeedItem) -> AnyView? {
        guard let post = item.payload as? Post, !post.allPhotoPaths.isEmpty else { return nil }
        return AnyView(PostParseSwipeAction(postId: post.id))
    }

    @MainActor
    func deleteFeedItem(_ item: FeedItem, context: CardDeleteContext) async {
        guard let post = item.payload as? Post else { return }
        let _: PostDeleteResponse? = try? await context.api.delete("/api/post/\(post.id)")
    }
}

/// Leading swipe action: parse photos via LLM
private struct PostParseSwipeAction: View {
    let postId: Int
    @Environment(APIClient.self) private var api
    @Environment(FeedStore.self) private var feedStore

    var body: some View {
        Button {
            Task {
                struct R: Codable { let id: Int; let status: String }
                let _: R? = try? await api.post("/api/post/\(postId)/parse-photos")
                // Poll until description appears (timeout 120s)
                let deadline = Date().addingTimeInterval(120)
                while Date() < deadline {
                    try? await Task.sleep(for: .seconds(2))
                    let post: Post? = try? await api.get("/api/post/\(postId)")
                    if let desc = post?.photoDescription, !desc.isEmpty {
                        await feedStore.refreshPost(id: postId)
                        break
                    }
                }
            }
        } label: {
            Label("Parse", systemImage: "doc.text.viewfinder")
        }
        .tint(.blue)
    }
}
