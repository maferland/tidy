import Foundation

struct CleanResult: Equatable {
    let cleaned: String
    let didChange: Bool
}

final class TextCleaner {
    func clean(_ text: String, settings: SettingsStore) -> CleanResult {
        var result = text

        if settings.stripTrailing {
            result = stripTrailingWhitespace(result)
        }
        if settings.collapseSpaces {
            result = collapseMultipleSpaces(result)
        }
        if settings.unwrapParagraphs {
            result = unwrapParagraphs(result)
        }
        if settings.trimIndent {
            result = trimCommonIndent(result)
        }
        if settings.collapseBlankLines {
            result = collapseConsecutiveBlankLines(result)
        }

        return CleanResult(cleaned: result, didChange: result != text)
    }

    func stripTrailingWhitespace(_ text: String) -> String {
        text.split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression) }
            .joined(separator: "\n")
    }

    func collapseMultipleSpaces(_ text: String) -> String {
        text.split(separator: "\n", omittingEmptySubsequences: false)
            .map { line in
                let str = String(line)
                let leadingSpaces = str.prefix(while: { $0 == " " || $0 == "\t" })
                let rest = str.dropFirst(leadingSpaces.count)
                let collapsed = rest.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
                return leadingSpaces + collapsed
            }
            .joined(separator: "\n")
    }

    func unwrapParagraphs(_ text: String) -> String {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard lines.count > 1 else { return text }

        var output: [String] = []
        var inCodeFence = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("```") {
                inCodeFence.toggle()
                output.append(line)
                continue
            }

            if inCodeFence {
                output.append(line)
                continue
            }

            guard let prev = output.last else {
                output.append(line)
                continue
            }

            let prevTrimmed = prev.trimmingCharacters(in: .whitespaces)

            if shouldJoin(previous: prevTrimmed, current: line, currentTrimmed: trimmed) {
                output[output.count - 1] = prev + " " + trimmed
            } else {
                output.append(line)
            }
        }

        return output.joined(separator: "\n")
    }

    func trimCommonIndent(_ text: String) -> String {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !nonEmptyLines.isEmpty else { return text }

        let minIndent = nonEmptyLines
            .map { $0.prefix(while: { $0 == " " }).count }
            .min() ?? 0

        guard minIndent > 0 else { return text }

        return lines.map { line in
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                return line
            }
            return String(line.dropFirst(min(minIndent, line.count)))
        }.joined(separator: "\n")
    }

    func collapseConsecutiveBlankLines(_ text: String) -> String {
        text.replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)
    }

    private func shouldJoin(previous: String, current: String, currentTrimmed: String) -> Bool {
        guard !previous.isEmpty else { return false }
        guard !previous.hasSuffix(":") else { return false }
        guard !previous.hasPrefix("```") else { return false }

        let hasLeadingSpace = current.first?.isWhitespace == true && !current.isEmpty && current != currentTrimmed
        guard hasLeadingSpace else { return false }

        guard !currentTrimmed.isEmpty else { return false }

        let listPrefixes = ["- ", "* ", "+ ", "# "]
        for prefix in listPrefixes {
            if currentTrimmed.hasPrefix(prefix) { return false }
        }
        if currentTrimmed.hasPrefix("`") { return false }
        if currentTrimmed.range(of: "^[0-9]+\\.", options: .regularExpression) != nil { return false }

        return true
    }
}
