import SwiftUI

/// A Text view that detects URLs in the string and renders them as tappable links.
struct LinkedText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(attributedString)
            .tint(.blue)
    }

    private var attributedString: AttributedString {
        var result = AttributedString(text)
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let nsString = text as NSString
        let range = NSRange(location: 0, length: nsString.length)

        guard let matches = detector?.matches(in: text, range: range) else { return result }

        for match in matches {
            guard let url = match.url,
                  let swiftRange = Range(match.range, in: text),
                  let attrRange = result.range(of: text[swiftRange])
            else { continue }

            result[attrRange].link = url
            result[attrRange].underlineStyle = .single
        }

        return result
    }
}
