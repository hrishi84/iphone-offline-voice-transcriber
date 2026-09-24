import XCTest
@testable import VoiceTranscriber

final class TextCleanupTests: XCTestCase {
    func testCollapsesWhitespace() {
        XCTAssertEqual(TextCleanup.clean("hello    world\n\nfoo"), "Hello world foo")
    }

    func testCapitalizesSentences() {
        XCTAssertEqual(TextCleanup.clean("hello world. how are you? fine!"), "Hello world. How are you? Fine!")
    }

    func testStripsFillerWords() {
        XCTAssertEqual(TextCleanup.clean("um so uh I think uhh it works"), "So I think it works")
    }

    func testDoesNotStripMeaningfulWords() {
        XCTAssertEqual(TextCleanup.clean("I like this a lot"), "I like this a lot")
    }

    func testEmptyInputStaysEmpty() {
        XCTAssertEqual(TextCleanup.clean(""), "")
    }

    func testIsIdempotent() {
        let once = TextCleanup.clean("um hello   world. this is uh a test.")
        let twice = TextCleanup.clean(once)
        XCTAssertEqual(once, twice)
    }
}
