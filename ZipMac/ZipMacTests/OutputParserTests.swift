import XCTest
@testable import ZipMac

final class OutputParserTests: XCTestCase {

    // MARK: - Progress Parsing

    func testParseProgress_percentageOnly() {
        let result = OutputParser.parseProgress(" 42%")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.progress, 0.42)
        XCTAssertNil(result!.currentFile)
    }

    func testParseProgress_percentageWithFile() {
        let result = OutputParser.parseProgress(" 75%  document.pdf")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.progress, 0.75)
        XCTAssertEqual(result!.currentFile, "document.pdf")
    }

    func testParseProgress_zeroPercent() {
        let result = OutputParser.parseProgress("  0%")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.progress, 0.0)
    }

    func testParseProgress_hundredPercent() {
        let result = OutputParser.parseProgress("100%")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.progress, 1.0)
    }

    func testParseProgress_nonProgressLine_returnsNil() {
        let result = OutputParser.parseProgress("Everything is Ok")
        XCTAssertNil(result)
    }

    func testParseProgress_emptyString_returnsNil() {
        let result = OutputParser.parseProgress("")
        XCTAssertNil(result)
    }

    // MARK: - Completion Detection

    func testIsCompletion_success() {
        XCTAssertTrue(OutputParser.isCompletion("Everything is Ok"))
    }

    func testIsCompletion_nonCompletion() {
        XCTAssertFalse(OutputParser.isCompletion(" 50%  file.txt"))
    }

    // MARK: - Archive Listing

    func testParseArchiveEntries() {
        let output = """
        7-Zip (z) 26.00 (arm64)

        Listing archive: test.7z

        --
        Path = test.7z
        Type = 7z

           Date      Time    Attr         Size   Compressed  Name
        ------------------- ----- ------------ ------------  ------------------------
        2024-01-15 10:30:00 D....            0            0  folder/
        2024-01-15 10:30:00 ....A         1234         5678  folder/file1.txt
        ------------------- ----- ------------ ------------  ------------------------
        2024-01-15 10:30:00                  1234         5678  1 files
        """
        let entries = OutputParser.parseArchiveEntries(output)
        XCTAssertEqual(entries.count, 2)
        XCTAssertTrue(entries[0].isDirectory)
        XCTAssertEqual(entries[0].name, "folder/")
        XCTAssertFalse(entries[1].isDirectory)
        XCTAssertEqual(entries[1].name, "folder/file1.txt")
        XCTAssertEqual(entries[1].size, 1234)
        XCTAssertEqual(entries[1].compressedSize, 5678)
    }

    func testParseArchiveEntries_emptyArchive() {
        let output = """
        7-Zip (z) 26.00

        Listing archive: empty.7z

        --
        Path = empty.7z
        Type = 7z

           Date      Time    Attr         Size   Compressed  Name
        ------------------- ----- ------------ ------------  ------------------------
        ------------------- ----- ------------ ------------  ------------------------
        """
        let entries = OutputParser.parseArchiveEntries(output)
        XCTAssertTrue(entries.isEmpty)
    }
}
