import SwiftUI

struct DocumentListView: View {
    @Environment(DocumentStore.self) private var store
    @Environment(Localizer.self) private var L
    @State private var showUpload = false
    @State private var selectedDocument: Document?

    var body: some View {
        List {
            if store.documents.isEmpty && !store.isLoading {
                Section {
                    Text(L.t("document.noDocuments"))
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(store.documents) { doc in
                NavigationLink {
                    DocumentDetailView(documentId: doc.id)
                } label: {
                    HStack {
                        Image(systemName: doc.originalType == "pdf" ? "doc.fill" : "photo.fill")
                            .foregroundStyle(doc.originalType == "pdf" ? .red : .blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(doc.filename)
                                .font(.subheadline)
                                .lineLimit(1)
                            if let summary = doc.summary {
                                Text(summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            } else if doc.status == "processing" {
                                HStack(spacing: 4) {
                                    ProgressView().scaleEffect(0.6)
                                    Text(L.t("document.processing"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } else if doc.status == "failed" {
                                Text(L.t("document.failed"))
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task { try? await store.delete(id: doc.id) }
                    } label: {
                        Label(L.t("common.delete"), systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(L.t("document.title"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showUpload = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showUpload, onDismiss: {
            Task { await store.load(force: true) }
        }) {
            DocumentUploadView()
        }
        .refreshable {
            await store.load(force: true)
        }
        .task {
            await store.load()
        }
    }
}

struct DocumentDetailView: View {
    let documentId: Int
    @Environment(DocumentStore.self) private var store
    @Environment(Localizer.self) private var L
    @State private var document: Document?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let doc = document {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Summary
                        if let summary = doc.summary {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L.t("document.summary"))
                                    .font(.headline)
                                Text(summary)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Divider()

                        // Extracted text
                        if let text = doc.extractedText {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L.t("document.extractedText"))
                                    .font(.headline)
                                Text(text)
                                    .font(.body)
                            }
                        } else if doc.status == "processing" {
                            HStack {
                                ProgressView()
                                Text(L.t("document.processing"))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else if isLoading {
                ProgressView()
            }
        }
        .navigationTitle(document?.filename ?? L.t("document.title"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                document = try await store.getDocument(documentId)
            } catch {}
            isLoading = false
        }
    }
}
