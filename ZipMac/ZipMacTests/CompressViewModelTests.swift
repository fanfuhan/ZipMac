import XCTest
@testable import ZipMac

final class CompressViewModelTests: XCTestCase {

    func testInitialState() {
        let viewModel = CompressViewModel()
        XCTAssertTrue(viewModel.selectedFiles.isEmpty)
        XCTAssertEqual(viewModel.format, .sevenZ)
        XCTAssertEqual(viewModel.level, 5)
        XCTAssertTrue(viewModel.volumeSize.isEmpty)
        XCTAssertTrue(viewModel.password.isEmpty)
        XCTAssertFalse(viewModel.isAdvancedMode)
    }

    func testAddFile() {
        let viewModel = CompressViewModel()
        let url = URL(fileURLWithPath: "/tmp/test.txt")
        viewModel.addFile(url)
        XCTAssertEqual(viewModel.selectedFiles.count, 1)
        XCTAssertEqual(viewModel.selectedFiles[0], url)
    }

    func testAddDuplicateFile_ignored() {
        let viewModel = CompressViewModel()
        let url = URL(fileURLWithPath: "/tmp/test.txt")
        viewModel.addFile(url)
        viewModel.addFile(url)
        XCTAssertEqual(viewModel.selectedFiles.count, 1)
    }

    func testRemoveFile() {
        let viewModel = CompressViewModel()
        let url = URL(fileURLWithPath: "/tmp/test.txt")
        viewModel.addFile(url)
        viewModel.removeFile(at: 0)
        XCTAssertTrue(viewModel.selectedFiles.isEmpty)
    }

    func testClearFiles() {
        let viewModel = CompressViewModel()
        viewModel.addFile(URL(fileURLWithPath: "/tmp/a.txt"))
        viewModel.addFile(URL(fileURLWithPath: "/tmp/b.txt"))
        viewModel.clearFiles()
        XCTAssertTrue(viewModel.selectedFiles.isEmpty)
    }

    func testDefaultOutputName_singleFile() {
        let viewModel = CompressViewModel()
        viewModel.addFile(URL(fileURLWithPath: "/tmp/document.pdf"))
        viewModel.format = .sevenZ
        XCTAssertEqual(viewModel.defaultOutputName, "document.7z")
    }

    func testDefaultOutputName_multipleFiles() {
        let viewModel = CompressViewModel()
        viewModel.addFile(URL(fileURLWithPath: "/tmp/a.txt"))
        viewModel.addFile(URL(fileURLWithPath: "/tmp/b.txt"))
        viewModel.format = .zip
        XCTAssertEqual(viewModel.defaultOutputName, "archive.zip")
    }

    func testIsValidVolumeSize() {
        let viewModel = CompressViewModel()
        XCTAssertTrue(viewModel.isValidVolumeSize("100m"))
        XCTAssertTrue(viewModel.isValidVolumeSize("1g"))
        XCTAssertTrue(viewModel.isValidVolumeSize("500k"))
        XCTAssertTrue(viewModel.isValidVolumeSize("1048576"))
        XCTAssertFalse(viewModel.isValidVolumeSize("abc"))
    }
}
