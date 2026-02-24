import Foundation
import Testing
@testable import Tidy

func makeTestSettings(
    stripTrailing: Bool = true,
    collapseSpaces: Bool = true,
    unwrapParagraphs: Bool = true,
    trimIndent: Bool = true,
    collapseBlankLines: Bool = true
) -> SettingsStore {
    let store = SettingsStore(userDefaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)
    store.stripTrailing = stripTrailing
    store.collapseSpaces = collapseSpaces
    store.unwrapParagraphs = unwrapParagraphs
    store.trimIndent = trimIndent
    store.collapseBlankLines = collapseBlankLines
    return store
}

// MARK: - Strip trailing whitespace

@Suite("TextCleaner — strip trailing whitespace")
struct StripTrailingTests {
    @Test("removes trailing spaces")
    func trailingSpaces() {
        #expect(TextCleaner.stripTrailingWhitespace("hello   ") == "hello")
    }

    @Test("removes trailing tabs")
    func trailingTabs() {
        #expect(TextCleaner.stripTrailingWhitespace("hello\t\t") == "hello")
    }

    @Test("preserves leading whitespace")
    func preservesLeading() {
        #expect(TextCleaner.stripTrailingWhitespace("  hello") == "  hello")
    }

    @Test("handles multiple lines")
    func multipleLines() {
        let input = "line1   \nline2\t\nline3"
        #expect(TextCleaner.stripTrailingWhitespace(input) == "line1\nline2\nline3")
    }

    @Test("preserves empty lines")
    func emptyLines() {
        #expect(TextCleaner.stripTrailingWhitespace("line1\n\nline3") == "line1\n\nline3")
    }

    @Test("handles empty string")
    func emptyString() {
        #expect(TextCleaner.stripTrailingWhitespace("") == "")
    }

    @Test("handles whitespace-only string")
    func whitespaceOnly() {
        #expect(TextCleaner.stripTrailingWhitespace("   ") == "")
    }
}

// MARK: - Collapse multiple spaces

@Suite("TextCleaner — collapse multiple spaces")
struct CollapseSpacesTests {
    @Test("collapses double spaces")
    func doubleSpaces() {
        #expect(TextCleaner.collapseMultipleSpaces("hello  world") == "hello world")
    }

    @Test("collapses many spaces")
    func manySpaces() {
        #expect(TextCleaner.collapseMultipleSpaces("hello     world") == "hello world")
    }

    @Test("preserves leading whitespace")
    func preservesLeading() {
        #expect(TextCleaner.collapseMultipleSpaces("    hello  world") == "    hello world")
    }

    @Test("preserves single spaces")
    func singleSpaces() {
        #expect(TextCleaner.collapseMultipleSpaces("hello world") == "hello world")
    }

    @Test("handles tabs in leading whitespace")
    func leadingTabs() {
        #expect(TextCleaner.collapseMultipleSpaces("\thello  world") == "\thello world")
    }

    @Test("handles empty string")
    func emptyString() {
        #expect(TextCleaner.collapseMultipleSpaces("") == "")
    }
}

// MARK: - Unwrap paragraphs

@Suite("TextCleaner — unwrap paragraphs")
struct UnwrapParagraphsTests {
    @Test("joins soft-wrapped continuation lines")
    func basicJoin() {
        let input = "This is a line that\n  wraps weirdly."
        #expect(TextCleaner.unwrapParagraphs(input) == "This is a line that wraps weirdly.")
    }

    @Test("preserves blank line paragraph boundaries")
    func blankLineBoundary() {
        let input = "Paragraph one.\n\nParagraph two."
        #expect(TextCleaner.unwrapParagraphs(input) == "Paragraph one.\n\nParagraph two.")
    }

    @Test("preserves bullet list items")
    func bulletLists() {
        let input = "Intro:\n  - item one\n  - item two"
        #expect(TextCleaner.unwrapParagraphs(input) == "Intro:\n  - item one\n  - item two")
    }

    @Test("preserves asterisk list items")
    func asteriskLists() {
        let input = "Intro:\n  * item one\n  * item two"
        #expect(TextCleaner.unwrapParagraphs(input) == "Intro:\n  * item one\n  * item two")
    }

    @Test("preserves plus list items")
    func plusLists() {
        #expect(TextCleaner.unwrapParagraphs("Intro:\n  + item one") == "Intro:\n  + item one")
    }

    @Test("preserves numbered list items")
    func numberedLists() {
        let input = "Intro:\n  1. first\n  2. second"
        #expect(TextCleaner.unwrapParagraphs(input) == "Intro:\n  1. first\n  2. second")
    }

    @Test("preserves headings")
    func headings() {
        #expect(TextCleaner.unwrapParagraphs("Some text\n  # Heading") == "Some text\n  # Heading")
    }

    @Test("preserves code fences entirely")
    func codeFences() {
        let input = "Before\n```\n  indented code\n  more code\n```\nAfter"
        #expect(TextCleaner.unwrapParagraphs(input) == input)
    }

    @Test("preserves code fences with language specifier")
    func codeFencesWithLang() {
        let input = "Before\n```swift\n  let x = 1\n```\nAfter"
        #expect(TextCleaner.unwrapParagraphs(input) == input)
    }

    @Test("preserves unclosed code fence")
    func unclosedCodeFence() {
        let input = "Before\n```\n  indented code\n  more code"
        #expect(TextCleaner.unwrapParagraphs(input) == input)
    }

    @Test("preserves inline code markers")
    func inlineCode() {
        #expect(TextCleaner.unwrapParagraphs("Some text\n  `code here`") == "Some text\n  `code here`")
    }

    @Test("does not join after colon")
    func afterColon() {
        #expect(TextCleaner.unwrapParagraphs("Header:\n  detail here") == "Header:\n  detail here")
    }

    @Test("joins multiple continuation lines")
    func multipleContinuations() {
        let input = "This is a long\n  sentence that\n  wraps multiple\n  times."
        #expect(TextCleaner.unwrapParagraphs(input) == "This is a long sentence that wraps multiple times.")
    }

    @Test("does not join lines without leading space")
    func noLeadingSpace() {
        #expect(TextCleaner.unwrapParagraphs("Line one\nLine two") == "Line one\nLine two")
    }

    @Test("single line unchanged")
    func singleLine() {
        #expect(TextCleaner.unwrapParagraphs("hello") == "hello")
    }

    @Test("handles empty string")
    func emptyString() {
        #expect(TextCleaner.unwrapParagraphs("") == "")
    }

    @Test("handles unicode and emoji")
    func unicode() {
        let input = "Hello world\n  with emoji test"
        #expect(TextCleaner.unwrapParagraphs(input) == "Hello world with emoji test")
    }
}

// MARK: - Trim common indent

@Suite("TextCleaner — trim common indent")
struct TrimIndentTests {
    @Test("trims common 4-space indent")
    func fourSpaces() {
        let input = "    line one\n    line two"
        #expect(TextCleaner.trimCommonIndent(input) == "line one\nline two")
    }

    @Test("trims to minimum indent")
    func mixedIndent() {
        let input = "    line one\n        line two"
        #expect(TextCleaner.trimCommonIndent(input) == "line one\n    line two")
    }

    @Test("ignores empty lines for min calculation")
    func emptyLines() {
        let input = "    line one\n\n    line two"
        #expect(TextCleaner.trimCommonIndent(input) == "line one\n\nline two")
    }

    @Test("no-op when no common indent")
    func noIndent() {
        let input = "line one\n    line two"
        #expect(TextCleaner.trimCommonIndent(input) == "line one\n    line two")
    }

    @Test("handles tab indentation")
    func tabIndent() {
        let input = "\t\tline one\n\t\tline two"
        #expect(TextCleaner.trimCommonIndent(input) == "line one\nline two")
    }

    @Test("handles empty string")
    func emptyString() {
        #expect(TextCleaner.trimCommonIndent("") == "")
    }

    @Test("handles whitespace-only lines")
    func whitespaceOnlyLines() {
        let input = "    line one\n    \n    line two"
        #expect(TextCleaner.trimCommonIndent(input) == "line one\n    \nline two")
    }
}

// MARK: - Collapse blank lines

@Suite("TextCleaner — collapse blank lines")
struct CollapseBlankLinesTests {
    @Test("collapses triple blank to double")
    func tripleBlank() {
        #expect(TextCleaner.collapseConsecutiveBlankLines("one\n\n\ntwo") == "one\n\ntwo")
    }

    @Test("collapses many blank lines")
    func manyBlanks() {
        #expect(TextCleaner.collapseConsecutiveBlankLines("one\n\n\n\n\ntwo") == "one\n\ntwo")
    }

    @Test("preserves single blank line")
    func singleBlank() {
        #expect(TextCleaner.collapseConsecutiveBlankLines("one\n\ntwo") == "one\n\ntwo")
    }

    @Test("handles empty string")
    func emptyString() {
        #expect(TextCleaner.collapseConsecutiveBlankLines("") == "")
    }
}

// MARK: - Full pipeline

@Suite("TextCleaner — full pipeline")
struct PipelineTests {
    @Test("cleans terminal-wrapped text")
    func terminalWrapped() {
        let input = "  This is a line that\n  wraps weirdly.  "
        let result = TextCleaner.clean(input, settings: makeTestSettings())
        #expect(result.cleaned == "This is a line that wraps weirdly.")
        #expect(result.didChange)
    }

    @Test("no change on clean text")
    func noChange() {
        let result = TextCleaner.clean("Already clean text.", settings: makeTestSettings())
        #expect(result.cleaned == "Already clean text.")
        #expect(!result.didChange)
    }

    @Test("respects all transforms disabled")
    func allDisabled() {
        let input = "hello   "
        let settings = makeTestSettings(
            stripTrailing: false,
            collapseSpaces: false,
            unwrapParagraphs: false,
            trimIndent: false,
            collapseBlankLines: false
        )
        let result = TextCleaner.clean(input, settings: settings)
        #expect(result.cleaned == "hello   ")
        #expect(!result.didChange)
    }

    @Test("each transform toggleable independently", arguments: [
        ("stripTrailing", "hello   ", "hello"),
        ("collapseSpaces", "hello  world", "hello world"),
        ("collapseBlankLines", "one\n\n\ntwo", "one\n\ntwo"),
    ])
    func individualTransform(name: String, input: String, expected: String) {
        let settings = makeTestSettings(
            stripTrailing: name == "stripTrailing",
            collapseSpaces: name == "collapseSpaces",
            unwrapParagraphs: false,
            trimIndent: false,
            collapseBlankLines: name == "collapseBlankLines"
        )
        let result = TextCleaner.clean(input, settings: settings)
        #expect(result.cleaned == expected)
    }

    @Test("full messy input")
    func fullMessy() {
        let input = "    First paragraph that   \n    continues here.  \n\n\n\n    - list item\n    - another item\n\n    ```\n    code block\n    ```"
        let result = TextCleaner.clean(input, settings: makeTestSettings())
        #expect(result.cleaned == "First paragraph that continues here.\n\n- list item\n- another item\n\n```\ncode block\n```")
        #expect(result.didChange)
    }

    @Test("empty string returns no change")
    func emptyString() {
        let result = TextCleaner.clean("", settings: makeTestSettings())
        #expect(result.cleaned == "")
        #expect(!result.didChange)
    }

    @Test("single character unchanged")
    func singleChar() {
        let result = TextCleaner.clean("x", settings: makeTestSettings())
        #expect(!result.didChange)
    }
}
