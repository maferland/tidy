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

@Suite("TextCleaner — strip trailing whitespace")
struct StripTrailingTests {
    let cleaner = TextCleaner()

    @Test("removes trailing spaces")
    func trailingSpaces() {
        #expect(cleaner.stripTrailingWhitespace("hello   ") == "hello")
    }

    @Test("removes trailing tabs")
    func trailingTabs() {
        #expect(cleaner.stripTrailingWhitespace("hello\t\t") == "hello")
    }

    @Test("preserves leading whitespace")
    func preservesLeading() {
        #expect(cleaner.stripTrailingWhitespace("  hello") == "  hello")
    }

    @Test("handles multiple lines")
    func multipleLines() {
        let input = "line1   \nline2\t\nline3"
        #expect(cleaner.stripTrailingWhitespace(input) == "line1\nline2\nline3")
    }

    @Test("preserves empty lines")
    func emptyLines() {
        let input = "line1\n\nline3"
        #expect(cleaner.stripTrailingWhitespace(input) == "line1\n\nline3")
    }
}

@Suite("TextCleaner — collapse multiple spaces")
struct CollapseSpacesTests {
    let cleaner = TextCleaner()

    @Test("collapses double spaces")
    func doubleSpaces() {
        #expect(cleaner.collapseMultipleSpaces("hello  world") == "hello world")
    }

    @Test("collapses many spaces")
    func manySpaces() {
        #expect(cleaner.collapseMultipleSpaces("hello     world") == "hello world")
    }

    @Test("preserves leading whitespace")
    func preservesLeading() {
        #expect(cleaner.collapseMultipleSpaces("    hello  world") == "    hello world")
    }

    @Test("preserves single spaces")
    func singleSpaces() {
        #expect(cleaner.collapseMultipleSpaces("hello world") == "hello world")
    }

    @Test("handles tabs in leading whitespace")
    func leadingTabs() {
        #expect(cleaner.collapseMultipleSpaces("\thello  world") == "\thello world")
    }
}

@Suite("TextCleaner — unwrap paragraphs")
struct UnwrapParagraphsTests {
    let cleaner = TextCleaner()

    @Test("joins soft-wrapped continuation lines")
    func basicJoin() {
        let input = "This is a line that\n  wraps weirdly."
        #expect(cleaner.unwrapParagraphs(input) == "This is a line that wraps weirdly.")
    }

    @Test("preserves blank line paragraph boundaries")
    func blankLineBoundary() {
        let input = "Paragraph one.\n\nParagraph two."
        #expect(cleaner.unwrapParagraphs(input) == "Paragraph one.\n\nParagraph two.")
    }

    @Test("preserves bullet list items")
    func bulletLists() {
        let input = "Intro:\n  - item one\n  - item two"
        #expect(cleaner.unwrapParagraphs(input) == "Intro:\n  - item one\n  - item two")
    }

    @Test("preserves asterisk list items")
    func asteriskLists() {
        let input = "Intro:\n  * item one\n  * item two"
        #expect(cleaner.unwrapParagraphs(input) == "Intro:\n  * item one\n  * item two")
    }

    @Test("preserves plus list items")
    func plusLists() {
        let input = "Intro:\n  + item one"
        #expect(cleaner.unwrapParagraphs(input) == "Intro:\n  + item one")
    }

    @Test("preserves numbered list items")
    func numberedLists() {
        let input = "Intro:\n  1. first\n  2. second"
        #expect(cleaner.unwrapParagraphs(input) == "Intro:\n  1. first\n  2. second")
    }

    @Test("preserves headings")
    func headings() {
        let input = "Some text\n  # Heading"
        #expect(cleaner.unwrapParagraphs(input) == "Some text\n  # Heading")
    }

    @Test("preserves code fences entirely")
    func codeFences() {
        let input = "Before\n```\n  indented code\n  more code\n```\nAfter"
        #expect(cleaner.unwrapParagraphs(input) == "Before\n```\n  indented code\n  more code\n```\nAfter")
    }

    @Test("preserves inline code markers")
    func inlineCode() {
        let input = "Some text\n  `code here`"
        #expect(cleaner.unwrapParagraphs(input) == "Some text\n  `code here`")
    }

    @Test("does not join after colon")
    func afterColon() {
        let input = "Header:\n  detail here"
        #expect(cleaner.unwrapParagraphs(input) == "Header:\n  detail here")
    }

    @Test("joins multiple continuation lines")
    func multipleContinuations() {
        let input = "This is a long\n  sentence that\n  wraps multiple\n  times."
        #expect(cleaner.unwrapParagraphs(input) == "This is a long sentence that wraps multiple times.")
    }

    @Test("does not join lines without leading space")
    func noLeadingSpace() {
        let input = "Line one\nLine two"
        #expect(cleaner.unwrapParagraphs(input) == "Line one\nLine two")
    }

    @Test("single line unchanged")
    func singleLine() {
        #expect(cleaner.unwrapParagraphs("hello") == "hello")
    }
}

@Suite("TextCleaner — trim common indent")
struct TrimIndentTests {
    let cleaner = TextCleaner()

    @Test("trims common 4-space indent")
    func fourSpaces() {
        let input = "    line one\n    line two"
        #expect(cleaner.trimCommonIndent(input) == "line one\nline two")
    }

    @Test("trims to minimum indent")
    func mixedIndent() {
        let input = "    line one\n        line two"
        #expect(cleaner.trimCommonIndent(input) == "line one\n    line two")
    }

    @Test("ignores empty lines for min calculation")
    func emptyLines() {
        let input = "    line one\n\n    line two"
        #expect(cleaner.trimCommonIndent(input) == "line one\n\nline two")
    }

    @Test("no-op when no common indent")
    func noIndent() {
        let input = "line one\n    line two"
        #expect(cleaner.trimCommonIndent(input) == "line one\n    line two")
    }
}

@Suite("TextCleaner — collapse blank lines")
struct CollapseBlankLinesTests {
    let cleaner = TextCleaner()

    @Test("collapses triple blank to double")
    func tripleBlank() {
        let input = "one\n\n\ntwo"
        #expect(cleaner.collapseConsecutiveBlankLines(input) == "one\n\ntwo")
    }

    @Test("collapses many blank lines")
    func manyBlanks() {
        let input = "one\n\n\n\n\ntwo"
        #expect(cleaner.collapseConsecutiveBlankLines(input) == "one\n\ntwo")
    }

    @Test("preserves single blank line")
    func singleBlank() {
        let input = "one\n\ntwo"
        #expect(cleaner.collapseConsecutiveBlankLines(input) == "one\n\ntwo")
    }
}

@Suite("TextCleaner — full pipeline")
struct PipelineTests {
    let cleaner = TextCleaner()

    @Test("cleans terminal-wrapped text")
    func terminalWrapped() {
        let input = "  This is a line that\n  wraps weirdly.  "
        let settings = makeTestSettings()
        let result = cleaner.clean(input, settings: settings)
        #expect(result.cleaned == "This is a line that wraps weirdly.")
        #expect(result.didChange)
    }

    @Test("no change on clean text")
    func noChange() {
        let input = "Already clean text."
        let settings = makeTestSettings()
        let result = cleaner.clean(input, settings: settings)
        #expect(result.cleaned == "Already clean text.")
        #expect(!result.didChange)
    }

    @Test("respects disabled transforms")
    func disabledTransforms() {
        let input = "hello   "
        let settings = makeTestSettings(
            stripTrailing: false,
            collapseSpaces: false,
            unwrapParagraphs: false,
            trimIndent: false,
            collapseBlankLines: false
        )
        let result = cleaner.clean(input, settings: settings)
        #expect(result.cleaned == "hello   ")
        #expect(!result.didChange)
    }

    @Test("full messy input")
    func fullMessy() {
        let input = "    First paragraph that   \n    continues here.  \n\n\n\n    - list item\n    - another item\n\n    ```\n    code block\n    ```"
        let settings = makeTestSettings()
        let result = cleaner.clean(input, settings: settings)
        #expect(result.cleaned == "First paragraph that continues here.\n\n- list item\n- another item\n\n```\ncode block\n```")
        #expect(result.didChange)
    }
}
