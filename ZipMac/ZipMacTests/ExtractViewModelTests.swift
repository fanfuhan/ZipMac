import XCTest
@testable import ZipMac

final class ExtractViewModelTests: XCTestCase {

    func testInitialState() {
        let viewModel = ExtractViewModel()
        XCTAssertNil(viewModel.selectedArchive)
        XCTAssertTrue(viewModel.password.isEmpty)
    }

    func testSetArchive() {
        let viewModel = ExtractViewModel()
        let url = URL(fileURLWithPath: "/tmp/test.7z")
        viewModel.setArchive(url)
        XCTAssertEqual(viewModel.selectedArchive, url)
    }

    func testClearArchive() {
        let viewModel = ExtractViewModel()
        viewModel.setArchive(URL(fileURLWithPath: "/tmp/test.7z"))
        viewModel.clearArchive()
        XCTAssertNil(viewModel.selectedArchive)
    }

    func testIsReadyToExtract_noArchive() {
        let viewModel = ExtractViewModel()
        XCTAssertFalse(viewModel.isReadyToExtract)
    }

    func testIsReadyToExtract_withArchive() {
        let viewModel = ExtractViewModel()
        viewModel.setArchive(URL(fileURLWithPath: "/tmp/test.7z"))
        XCTAssertTrue(viewModel.isReadyToExtract)
    }
}
