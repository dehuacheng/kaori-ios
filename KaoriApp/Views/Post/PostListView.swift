import SwiftUI

struct PostListView: View {
    @Environment(PostStore.self) private var store
    @Environment(Localizer.self) private var L
    @State private var showCreate = false

    var body: some View {
        List {
            if store.posts.isEmpty && !store.isLoading {
                Section {
                    Text(L.t("post.noPosts"))
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(store.posts) { post in
                NavigationLink {
                    PostDetailView(post: post)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(post.content)
                            .font(.subheadline)
                            .lineLimit(2)
                        Text(post.date)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .navigationTitle(L.t("post.title"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreate, onDismiss: {
            Task { await store.load(force: true) }
        }) {
            PostCreateView()
        }
        .refreshable {
            await store.load(force: true)
        }
        .task {
            await store.load()
        }
    }
}
