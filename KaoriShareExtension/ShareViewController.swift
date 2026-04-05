import UIKit
import SwiftUI
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let sharedContent = SharedContent()
        extractAttachments(into: sharedContent)
    }

    private func extractAttachments(into content: SharedContent) {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            presentCompose(content: content)
            return
        }

        let attachments = extensionItems.compactMap(\.attachments).flatMap { $0 }
        guard !attachments.isEmpty else {
            presentCompose(content: content)
            return
        }

        let group = DispatchGroup()
        var texts: [String] = []
        var urls: [String] = []

        for attachment in attachments {
            // Image
            if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                group.enter()
                attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, _ in
                    defer { group.leave() }
                    var image: UIImage?
                    if let url = item as? URL, let data = try? Data(contentsOf: url) {
                        image = UIImage(data: data)
                    } else if let data = item as? Data {
                        image = UIImage(data: data)
                    } else if let img = item as? UIImage {
                        image = img
                    }
                    if let image, let jpeg = Self.resized(image).jpegData(compressionQuality: 0.8) {
                        DispatchQueue.main.async { content.imageData = jpeg }
                    }
                }
            }

            // URL
            if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                group.enter()
                attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                    defer { group.leave() }
                    if let url = item as? URL {
                        urls.append(url.absoluteString)
                    }
                }
            }

            // Plain text
            if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                group.enter()
                attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                    defer { group.leave() }
                    if let text = item as? String {
                        texts.append(text)
                    }
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            // Combine extracted text and URLs
            var parts: [String] = []
            parts.append(contentsOf: texts)
            // Only add URLs that aren't already in the text
            for url in urls {
                if !texts.contains(where: { $0.contains(url) }) {
                    parts.append(url)
                }
            }
            content.text = parts.joined(separator: "\n\n")
            content.sharedURLs = urls
            self?.presentCompose(content: content)

            // Fetch metadata for shared URLs in background
            if !urls.isEmpty {
                Task {
                    await self?.fetchMetadata(for: urls, into: content)
                }
            }
        }
    }

    private func fetchMetadata(for urls: [String], into content: SharedContent) async {
        let fetcher = URLMetadataFetcher()
        guard let urlString = urls.first,
              let metadata = await fetcher.fetch(from: urlString) else { return }

        // Build enriched text: title + description + URL
        var parts: [String] = []
        if let title = metadata.title {
            parts.append(title)
        }
        if let description = metadata.description {
            parts.append(description)
        }
        parts.append(urlString)

        await MainActor.run {
            content.text = parts.joined(separator: "\n\n")
            content.isFetchingMetadata = false
        }

        // Fetch OG image if no image was shared directly
        if content.imageData == nil, let imageURL = metadata.imageURL {
            if let imageData = await fetcher.fetchImage(from: imageURL) {
                await MainActor.run {
                    content.imageData = imageData
                }
            }
        }
    }

    private func presentCompose(content: SharedContent) {
        // Mark as fetching if there are URLs to enrich
        if !content.sharedURLs.isEmpty {
            content.isFetchingMetadata = true
        }

        let composeView = ShareComposeView(content: content) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil)
        } onCancel: { [weak self] in
            self?.extensionContext?.cancelRequest(withError: NSError(domain: "com.dehuacheng.kaori", code: 0))
        }

        let hostingController = UIHostingController(rootView: composeView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        hostingController.didMove(toParent: self)
    }

    static func resized(_ image: UIImage, maxDimension: CGFloat = 1600) -> UIImage {
        let size = image.size
        guard max(size.width, size.height) > maxDimension else { return image }
        let scale = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}

@Observable
class SharedContent {
    var text: String = ""
    var imageData: Data?
    var sharedURLs: [String] = []
    var isFetchingMetadata = false
}
