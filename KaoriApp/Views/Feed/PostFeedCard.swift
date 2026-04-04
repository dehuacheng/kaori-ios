import SwiftUI

struct PostFeedCard: View {
    let post: Post
    var displayTime: String?

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

            Text(post.content)
                .font(.subheadline)
                .lineLimit(4)
        }
        .feedCard()
    }
}
