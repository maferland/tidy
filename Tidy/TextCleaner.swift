import Foundation

struct CleanResult: Equatable {
    let cleaned: String
    let didChange: Bool
}

enum TextCleaner {
    static func clean(_ text: String, settings: SettingsStore) -> CleanResult {
        var result = text

        if settings.stripTrailing {
            result = stripTrailingWhitespace(result)
        }

        let isShellContinuation = result.contains("\\\n")
        if settings.collapseSpaces {
            result = collapseMultipleSpaces(result)
        }
        if settings.unwrapParagraphs && !isShellContinuation {
            result = unwrapParagraphs(result)
        }
        if settings.trimIndent && !isShellContinuation {
            result = trimCommonIndent(result)
        }
        if settings.collapseBlankLines {
            result = collapseConsecutiveBlankLines(result)
        }

        return CleanResult(cleaned: result, didChange: result != text)
    }

    static func stripTrailingWhitespace(_ text: String) -> String {
        text.components(separatedBy: "\n")
            .map { $0.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression) }
            .joined(separator: "\n")
    }

    static func collapseMultipleSpaces(_ text: String) -> String {
        text.components(separatedBy: "\n")
            .map { line in
                let leading = String(line.prefix(while: { $0 == " " || $0 == "\t" }))
                let rest = line.dropFirst(leading.count)
                let collapsed = rest.replacingOccurrences(of: " {2,}", with: " ", options: .regularExpression)
                return leading + collapsed
            }
            .joined(separator: "\n")
    }

    static func unwrapParagraphs(_ text: String) -> String {
        let lines = text.components(separatedBy: "\n")
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

    static func trimCommonIndent(_ text: String) -> String {
        let lines = text.components(separatedBy: "\n")

        let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !nonEmptyLines.isEmpty else { return text }

        let minIndent = nonEmptyLines
            .map { $0.prefix(while: { $0.isWhitespace }).count }
            .min() ?? 0

        guard minIndent > 0 else { return text }

        return lines.map { line in
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                return line
            }
            return String(line.dropFirst(min(minIndent, line.count)))
        }.joined(separator: "\n")
    }

    static func collapseConsecutiveBlankLines(_ text: String) -> String {
        text.replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)
    }

    private static func shouldJoin(previous: String, current: String, currentTrimmed: String) -> Bool {
        guard !previous.isEmpty else { return false }
        guard !previous.hasSuffix(":") else { return false }
        guard !previous.hasPrefix("```") else { return false }

        let hasLeadingSpace = current.first?.isWhitespace == true && !current.isEmpty && current != currentTrimmed
        guard hasLeadingSpace else { return false }
        guard !currentTrimmed.isEmpty else { return false }

        let structuralPrefixes = ["- ", "* ", "+ ", "# "]
        for prefix in structuralPrefixes {
            if currentTrimmed.hasPrefix(prefix) { return false }
        }
        if currentTrimmed.hasPrefix("`") { return false }
        if currentTrimmed.range(of: "^[0-9]+\\.", options: .regularExpression) != nil { return false }

        return true
    }
}
