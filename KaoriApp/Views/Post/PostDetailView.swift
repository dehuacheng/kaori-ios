import SwiftUI

struct PostDetailView: View {
    let post: Post
    @Environment(PostStore.self) private var store
    @Environment(Localizer.self) private var L
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(post.content)
                    .font(.body)

                HStack {
                    Text(post.date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let time = formatLocalTime(post.createdAt) {
                        Text(time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(L.t("post.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label(L.t("common.delete"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert(L.t("post.deletePost"), isPresented: $showDeleteConfirm) {
            Button(L.t("common.delete"), role: .destructive) {
                Task {
                    try? await store.delete(id: post.id)
                    dismiss()
                }
            }
            Button(L.t("common.cancel"), role: .cancel) {}
        }
    }
}
