import SwiftUI
import PhotosUI

struct HoldingsImportView: View {
    @Environment(Localizer.self) private var L
    @Environment(FinanceStore.self) private var financeStore
    @Environment(\.dismiss) private var dismiss

    let account: FinancialAccount

    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var imageDatas: [Data] = []
    @State private var isUploading = false
    @State private var analysisId: Int?
    @State private var isPolling = false
    @State private var extractedPositions: [ExtractedPosition] = []
    @State private var analysisError: String?
    @State private var analysisDone = false

    var body: some View {
        NavigationStack {
            Group {
                if analysisDone {
                    reviewView
                } else if isUploading || isPolling {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text(isUploading ? L.t("finance.uploading") : L.t("finance.analyzing"))
                            .foregroundStyle(.secondary)
                        if imageDatas.count > 1 {
                            Text(String(format: L.t("finance.photosCount"), imageDatas.count))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = analysisError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.red)
                        Text(error)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button(L.t("common.retry")) {
                            analysisError = nil
                            selectedPhotos = []
                            imageDatas = []
                        }
                    }
                    .padding()
                } else {
                    pickerView
                }
            }
            .navigationTitle(L.t("finance.importHoldings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.t("common.cancel")) { dismiss() }
                }
            }
        }
    }

    private var pickerView: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text(L.t("finance.importHint"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 10, matching: .images) {
                Label(L.t("finance.selectScreenshots"), systemImage: "photo.on.rectangle.angled")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            .onChange(of: selectedPhotos) {
                Task { await handlePhotoPick() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var reviewView: some View {
        List {
            Section(L.t("finance.extractedPositions")) {
                ForEach(Array(extractedPositions.indices), id: \.self) { idx in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            TextField(L.t("finance.ticker"), text: $extractedPositions[idx].ticker)
                                .font(.body.bold().monospaced())
                                .textInputAutocapitalization(.characters)
                                .frame(maxWidth: 100)
                            Spacer()
                            if let desc = extractedPositions[idx].description {
                                Text(desc)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Text(L.t("finance.shares"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("0", value: Binding(
                                    get: { extractedPositions[idx].shares },
                                    set: { extractedPositions[idx].shares = $0 }
                                ), format: .number)
                                    .font(.caption.monospaced())
                                    .keyboardType(.decimalPad)
                                    .frame(maxWidth: 80)
                                    .multilineTextAlignment(.trailing)
                            }
                            HStack(spacing: 4) {
                                Text("$")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("—", value: $extractedPositions[idx].costBasis, format: .number)
                                    .font(.caption.monospaced())
                                    .keyboardType(.decimalPad)
                                    .frame(maxWidth: 80)
                                    .multilineTextAlignment(.trailing)
                                Text(L.t("finance.perShare"))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .onDelete { offsets in
                    extractedPositions.remove(atOffsets: offsets)
                }
            }

            Section {
                Button {
                    Task { await confirmImport() }
                } label: {
                    HStack {
                        Spacer()
                        Text(L.t("finance.confirmImport"))
                            .bold()
                        Spacer()
                    }
                }
                .disabled(extractedPositions.isEmpty)
            }
        }
    }

    // MARK: - Logic

    private func handlePhotoPick() async {
        guard !selectedPhotos.isEmpty else { return }
        isUploading = true

        // Step 1: Load raw data from PhotosPicker (must stay on calling context)
        var rawDatas: [Data] = []
        for item in selectedPhotos {
            if let data = try? await item.loadTransferable(type: Data.self) {
                rawDatas.append(data)
            }
        }
        guard !rawDatas.isEmpty else {
            isUploading = false
            return
        }

        // Step 2: Compress off main thread
        let captured = rawDatas
        let compressed: [Data] = await Task.detached {
            captured.compactMap { compressImageForUpload($0) }
        }.value

        guard !compressed.isEmpty else {
            isUploading = false
            return
        }
        imageDatas = compressed
        await uploadAndAnalyze()
    }

    private func uploadAndAnalyze() async {
        guard !imageDatas.isEmpty else { return }

        do {
            let response = try await financeStore.uploadImport(accountId: account.id, images: imageDatas)
            analysisId = response.analysisId
            isUploading = false
            isPolling = true
            await pollAnalysis()
        } catch {
            isUploading = false
            analysisError = error.localizedDescription
        }
    }

    private func pollAnalysis() async {
        guard let id = analysisId else { return }
        for i in 0..<120 {  // Poll for up to 4 minutes
            // First iteration: wait 2s (give LLM a head start), then 2s between polls
            if i == 0 {
                try? await Task.sleep(for: .seconds(2))
            } else {
                try? await Task.sleep(for: .seconds(2))
            }
            do {
                let analysis = try await financeStore.getImportAnalysis(id)
                if analysis.status == "done" {
                    if let extracted = analysis.extracted, !extracted.positions.isEmpty {
                        extractedPositions = extracted.positions
                        analysisDone = true
                    } else {
                        analysisError = "No positions found in the screenshot"
                    }
                    isPolling = false
                    return
                } else if analysis.status == "failed" {
                    analysisError = analysis.errorMessage ?? "Analysis failed"
                    isPolling = false
                    return
                }
            } catch {
                // Continue polling on network errors
            }
        }
        isPolling = false
        analysisError = "Analysis timed out"
    }

    private func confirmImport() async {
        let holdings = extractedPositions.compactMap { pos -> HoldingBulkEntry? in
            guard let shares = pos.shares, shares > 0 else { return nil }
            return HoldingBulkEntry(
                ticker: pos.ticker,
                shares: shares,
                costBasis: pos.costBasis,
                description: pos.description
            )
        }
        do {
            guard let id = analysisId else { return }
            try await financeStore.confirmImport(analysisId: id, holdings: holdings)
            dismiss()
        } catch {
            analysisError = error.localizedDescription
        }
    }
}

/// Resize to max 1600px and compress as JPEG quality 0.7 — nonisolated so it can run off main thread
private func compressImageForUpload(_ data: Data) -> Data? {
    guard let image = UIImage(data: data) else { return data }
    let maxDim: CGFloat = 1600
    let scale = min(maxDim / max(image.size.width, image.size.height), 1.0)
    if scale < 1.0 {
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        return resized.jpegData(compressionQuality: 0.7)
    }
    return image.jpegData(compressionQuality: 0.7)
}
