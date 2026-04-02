import SwiftUI

struct SummarySectionsView: View {
    let markdown: String
    @Binding var allCollapsed: Bool

    @State private var expandedSections: Set<String> = []
    @State private var initialized = false

    var body: some View {
        let parsed = parseSections(markdown)
        VStack(alignment: .leading, spacing: 6) {
            // Preamble (always visible commentary)
            if !parsed.preamble.isEmpty {
                MarkdownText(parsed.preamble)
                    .font(.subheadline)
            }

            // Collapsible sections
            if !allCollapsed {
                ForEach(parsed.sections) { section in
                    DisclosureGroup(
                        isExpanded: bindingForSection(section.title)
                    ) {
                        MarkdownText(section.body)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: iconForSection(section.title))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(section.title)
                                .font(.subheadline.bold())
                        }
                    }
                }
            }
        }
        .onAppear {
            if !initialized {
                // Start with all sections expanded
                let parsed = parseSections(markdown)
                expandedSections = Set(parsed.sections.map(\.title))
                initialized = true
            }
        }
        .onChange(of: allCollapsed) { _, collapsed in
            withAnimation {
                if collapsed {
                    expandedSections.removeAll()
                } else {
                    let parsed = parseSections(markdown)
                    expandedSections = Set(parsed.sections.map(\.title))
                }
            }
        }
    }

    private func bindingForSection(_ title: String) -> Binding<Bool> {
        Binding(
            get: { expandedSections.contains(title) },
            set: { expanded in
                if expanded {
                    expandedSections.insert(title)
                } else {
                    expandedSections.remove(title)
                }
            }
        )
    }

    // MARK: - Markdown Rendering

    private struct MarkdownText: View {
        let text: String

        init(_ text: String) {
            self.text = text
        }

        var body: some View {
            if let attributed = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                Text(attributed)
            } else {
                Text(text)
            }
        }
    }

    // MARK: - Section Icons

    private func iconForSection(_ title: String) -> String {
        let lower = title.lowercased()
        if lower.contains("nutrition") || lower.contains("营养") { return "fork.knife" }
        if lower.contains("activity") || lower.contains("活动") || lower.contains("训练") || lower.contains("training") { return "figure.run" }
        if lower.contains("weight") || lower.contains("体重") { return "scalemass" }
        if lower.contains("streak") || lower.contains("连续") { return "flame" }
        if lower.contains("tip") || lower.contains("建议") || lower.contains("plan") || lower.contains("计划") { return "lightbulb" }
        if lower.contains("highlight") || lower.contains("亮点") { return "star" }
        return "doc.text"
    }

    // MARK: - Parsing

    private struct ParsedSummary {
        let preamble: String
        let sections: [SummarySection]
    }

    private func parseSections(_ text: String) -> ParsedSummary {
        var sections: [SummarySection] = []
        var currentTitle = ""
        var currentLines: [String] = []
        var preamble = ""

        for line in text.components(separatedBy: "\n") {
            if line.hasPrefix("## ") {
                let body = currentLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                if currentTitle.isEmpty {
                    preamble = body
                } else if !body.isEmpty {
                    sections.append(SummarySection(title: currentTitle, body: body))
                }
                currentTitle = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                currentLines = []
            } else {
                currentLines.append(line)
            }
        }

        let body = currentLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        if !currentTitle.isEmpty && !body.isEmpty {
            sections.append(SummarySection(title: currentTitle, body: body))
        } else if currentTitle.isEmpty && preamble.isEmpty {
            preamble = body
        }

        return ParsedSummary(preamble: preamble, sections: sections)
    }
}

private struct SummarySection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}
