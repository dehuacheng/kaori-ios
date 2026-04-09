import SwiftUI

struct PostDetailView: View {
    let post: Post
    @Environment(PostStore.self) private var store
    @Environment(APIClient.self) private var api
    @Environment(Localizer.self) private var L
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                let paths = post.allPhotoPaths
                if paths.count == 1, let url = api.photoURL(for: paths[0]) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 300)
                            .overlay { ProgressView() }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else if paths.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(paths, id: \.self) { path in
                                if let url = api.photoURL(for: path) {
                                    AsyncImage(url: url) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.05))
                                            .overlay { ProgressView() }
                                    }
                                    .frame(width: 240, height: 240)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                }

                LinkedText(post.content)
                    .font(.body)

                if let photoDesc = post.photoDescription {
                    DisclosureGroup(L.t("photo.description")) {
                        Text(photoDesc)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }

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
