import SwiftUI

struct ShareComposeView: View {
    @Bindable var content: SharedContent
    let onComplete: () -> Void
    let onCancel: () -> Void

    @State private var postDate = Date()
    @State private var isSaving = false
    @State private var error: String?

    private let api = ShareExtensionAPIClient()

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private var isChinese: Bool {
        SharedConfig.appLanguage.hasPrefix("zh")
    }

    var body: some View {
        NavigationStack {
            Form {
                if !SharedConfig.isConfigured {
                    Section {
                        Text(isChinese ? "请先打开 Kaori 并配置服务器" : "Open Kaori and configure server settings first")
                            .foregroundStyle(.secondary)
                    }
                }

                Section(isChinese ? "内容" : "Content") {
                    if content.isFetchingMetadata {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text(isChinese ? "获取链接信息..." : "Fetching link info...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    TextEditor(text: $content.text)
                        .frame(minHeight: 120)
                }

                if let imageData = content.imageData, let uiImage = UIImage(data: imageData) {
                    Section(isChinese ? "照片" : "Photo") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                Section {
                    DatePicker(
                        isChinese ? "日期" : "Date",
                        selection: $postDate,
                        displayedComponents: .date
                    )
                }

                if let error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                        Button(isChinese ? "重试" : "Retry") {
                            Task { await save() }
                        }
                    }
                }
            }
            .navigationTitle(isChinese ? "保存到 Kaori" : "Save to Kaori")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isChinese ? "取消" : "Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(isChinese ? "保存" : "Save") {
                            Task { await save() }
                        }
                        .disabled(content.text.isEmpty || !SharedConfig.isConfigured)
                    }
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        error = nil
        do {
            try await api.createPost(
                content: content.text,
                date: dateFormatter.string(from: postDate),
                imageData: content.imageData
            )
            onComplete()
        } catch let apiError as ShareAPIError {
            switch apiError {
            case .notConfigured:
                error = isChinese ? "请先打开 Kaori 并配置服务器" : "Open Kaori and configure server settings first"
            case .networkUnavailable:
                error = isChinese ? "无法连接服务器 — 请检查 Tailscale" : "Server unreachable — is Tailscale connected?"
            case .unauthorized:
                error = isChinese ? "认证失败 — 请在设置中检查 Token" : "Authentication failed — check token in Settings"
            case .serverError(let code):
                error = isChinese ? "服务器错误 (\(code))" : "Server error (\(code))"
            case .unknown(let err):
                error = err.localizedDescription
            }
        } catch {
            self.error = error.localizedDescription
        }
        isSaving = false
    }
}
