import SwiftUI

struct PostFeedCard: View {
    let post: Post
    var displayTime: String?
    @Environment(APIClient.self) private var api

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundStyle(.purple)
                Text("Post")
                    .font(.subheadline.bold())
                    .foregroundStyle(.purple)
                Spacer()
                if let time = displayTime {
                    Text(time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            let paths = post.allPhotoPaths
            if paths.count == 1, let url = api.photoURL(for: paths[0]) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 200)
                        .overlay { ProgressView() }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.vertical, 2)
            } else if paths.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(paths, id: \.self) { path in
                            if let url = api.photoURL(for: path) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.05))
                                        .overlay { ProgressView() }
                                }
                                .frame(width: 160, height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            Text(post.content)
                .font(.subheadline)
                .lineLimit(4)
        }
        .feedCard()
    }
}
