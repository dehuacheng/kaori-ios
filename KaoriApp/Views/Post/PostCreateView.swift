import SwiftUI

struct PostCreateView: View {
    @Environment(PostStore.self) private var store
    @Environment(Localizer.self) private var L
    @Environment(\.dismiss) private var dismiss

    @State private var content = ""
    @State private var postDate = Date()
    @State private var imagesData: [Data] = []
    @State private var isSubmitting = false
    @State private var error: String?

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        NavigationStack {
            Form {
                Section(L.t("post.content")) {
                    TextEditor(text: $content)
                        .frame(minHeight: 120)
                }

                Section(L.t("meal.photo")) {
                    MultiPhotoPickerButton(imagesData: $imagesData)
                }

                Section {
                    DatePicker(L.t("post.date"), selection: $postDate, displayedComponents: .date)
                }

                if let error {
                    Section {
                        Text(error).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle(L.t("post.newPost"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.t("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.t("common.save")) {
                        Task { await submit() }
                    }
                    .disabled(content.isEmpty || isSubmitting)
                }
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        error = nil
        do {
            try await store.create(
                date: dateFormatter.string(from: postDate),
                title: nil,
                content: content,
                photos: imagesData.isEmpty ? nil : imagesData
            )
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isSubmitting = false
    }
}
