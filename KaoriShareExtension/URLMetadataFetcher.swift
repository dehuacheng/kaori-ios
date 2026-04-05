import Foundation
import UIKit

struct URLMetadata {
    var title: String?
    var description: String?
    var imageURL: String?
}

struct URLMetadataFetcher {

    /// Fetches Open Graph metadata from a URL. Returns nil on failure.
    func fetch(from urlString: String) async -> URLMetadata? {
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        // Some sites require a browser-like User-Agent to return OG tags
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .unicode)
        else { return nil }

        let title = extractMetaContent(from: html, property: "og:title")
            ?? extractMetaContent(from: html, name: "title")
            ?? extractTitle(from: html)
        let description = extractMetaContent(from: html, property: "og:description")
            ?? extractMetaContent(from: html, name: "description")
        let imageURL = extractMetaContent(from: html, property: "og:image")

        guard title != nil || description != nil else { return nil }

        return URLMetadata(title: title, description: description, imageURL: imageURL)
    }

    /// Downloads an image from a URL, resizes and compresses to JPEG.
    func fetchImage(from urlString: String) async -> Data? {
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type"),
              contentType.hasPrefix("image/"),
              let image = UIImage(data: data)
        else { return nil }

        let resized = resizeImage(image, maxDimension: 1600)
        return resized.jpegData(compressionQuality: 0.8)
    }

    // MARK: - HTML Parsing

    /// Extracts content from <meta property="X" content="Y">
    private func extractMetaContent(from html: String, property: String) -> String? {
        // Match both property="og:title" and name="og:title" patterns
        let patterns = [
            "<meta[^>]+property=[\"']\(NSRegularExpression.escapedPattern(for: property))[\"'][^>]+content=[\"']([^\"']*)[\"']",
            "<meta[^>]+content=[\"']([^\"']*)[\"'][^>]+property=[\"']\(NSRegularExpression.escapedPattern(for: property))[\"']"
        ]
        for pattern in patterns {
            if let match = firstMatch(in: html, pattern: pattern) {
                let trimmed = match.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { return decodeHTMLEntities(trimmed) }
            }
        }
        return nil
    }

    /// Extracts content from <meta name="X" content="Y">
    private func extractMetaContent(from html: String, name: String) -> String? {
        let patterns = [
            "<meta[^>]+name=[\"']\(NSRegularExpression.escapedPattern(for: name))[\"'][^>]+content=[\"']([^\"']*)[\"']",
            "<meta[^>]+content=[\"']([^\"']*)[\"'][^>]+name=[\"']\(NSRegularExpression.escapedPattern(for: name))[\"']"
        ]
        for pattern in patterns {
            if let match = firstMatch(in: html, pattern: pattern) {
                let trimmed = match.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { return decodeHTMLEntities(trimmed) }
            }
        }
        return nil
    }

    /// Extracts content from <title>X</title>
    private func extractTitle(from html: String) -> String? {
        if let match = firstMatch(in: html, pattern: "<title[^>]*>([^<]+)</title>") {
            let trimmed = match.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return decodeHTMLEntities(trimmed) }
        }
        return nil
    }

    private func firstMatch(in string: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(string.startIndex..., in: string)
        guard let match = regex.firstMatch(in: string, range: range), match.numberOfRanges > 1 else { return nil }
        guard let captureRange = Range(match.range(at: 1), in: string) else { return nil }
        return String(string[captureRange])
    }

    private func decodeHTMLEntities(_ string: String) -> String {
        var result = string
        let entities: [(String, String)] = [
            ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"),
            ("&quot;", "\""), ("&#39;", "'"), ("&apos;", "'"),
            ("&#x27;", "'"), ("&#x2F;", "/"), ("&nbsp;", " "),
        ]
        for (entity, char) in entities {
            result = result.replacingOccurrences(of: entity, with: char)
        }
        return result
    }

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard max(size.width, size.height) > maxDimension else { return image }
        let scale = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
