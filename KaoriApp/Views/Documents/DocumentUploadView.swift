import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct DocumentUploadView: View {
    @Environment(DocumentStore.self) private var store
    @Environment(Localizer.self) private var L
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var photosData: [Data] = []
    @State private var pdfData: Data?
    @State private var pdfFileName: String?
    @State private var isSubmitting = false
    @State private var error: String?
    @State private var showFilePicker = false
    @State private var uploadResult: DocumentUploadResponse?

    private var hasFiles: Bool {
        !photosData.isEmpty || pdfData != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(L.t("document.selectFile")) {
                    PhotosPicker(
                        selection: $selectedPhotoItems,
                        maxSelectionCount: 20,
                        matching: .images
                    ) {
                        Label(L.t("document.pickPhotos"), systemImage: "photo.on.rectangle.angled")
                    }

                    Button {
                        showFilePicker = true
                    } label: {
                        Label(L.t("document.pickPDF"), systemImage: "doc.fill")
                    }
                }

                if !photosData.isEmpty {
                    Section(L.t("document.selected")) {
                        HStack {
                            Image(systemName: "photo.fill")
                                .foregroundStyle(.blue)
                            Text(L.t("document.photosSelected", photosData.count))
                                .font(.subheadline)
                        }
                    }
                } else if let pdfFileName {
                    Section(L.t("document.selected")) {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundStyle(.red)
                            Text(pdfFileName)
                                .font(.subheadline)
                        }
                    }
                }

                if let error {
                    Section {
                        Text(error).foregroundStyle(.red).font(.caption)
                    }
                }

                if let result = uploadResult {
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            Label(L.t("document.uploaded"), systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            if let count = result.pageCount, count > 1 {
                                Text(L.t("document.pagesUploaded", count))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(L.t("document.processingHint"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(L.t("document.upload"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.t("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.t("document.upload")) {
                        Task { await submit() }
                    }
                    .disabled(!hasFiles || isSubmitting)
                }
            }
            .onChange(of: selectedPhotoItems) { _, items in
                Task { await loadPhotos(items) }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [UTType.pdf],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
        }
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) async {
        var loaded: [Data] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                loaded.append(data)
            }
        }
        photosData = loaded
        // Clear PDF if photos are selected
        if !loaded.isEmpty {
            pdfData = nil
            pdfFileName = nil
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            do {
                pdfData = try Data(contentsOf: url)
                pdfFileName = url.lastPathComponent
                // Clear photos if PDF is selected
                photosData = []
                selectedPhotoItems = []
            } catch {
                self.error = error.localizedDescription
            }
        case .failure(let error):
            self.error = error.localizedDescription
        }
    }

    private func submit() async {
        isSubmitting = true
        error = nil
        do {
            if let pdfData, let pdfFileName {
                uploadResult = try await store.upload(
                    filesData: [(data: pdfData, filename: pdfFileName, mimeType: "application/pdf")]
                )
            } else if !photosData.isEmpty {
                let files = photosData.enumerated().map { (i, data) in
                    (data: data, filename: "photo\(i).jpg", mimeType: "image/jpeg")
                }
                uploadResult = try await store.upload(filesData: files)
            }
        } catch {
            self.error = error.localizedDescription
        }
        isSubmitting = false
    }
}
