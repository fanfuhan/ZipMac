import XCTest
@testable import ZipMac

final class SevenZipServiceTests: XCTestCase {

    var service: SevenZipService!

    override func setUp() {
        super.setUp()
        let binaryPath = "/Users/fh.fan/Desktop/zip/7zz"
        service = SevenZipService(binaryPath: binaryPath)
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    func testCustomBinaryPath() {
        let svc = SevenZipService(binaryPath: "/usr/local/bin/7zz")
        XCTAssertEqual(svc.resolvedBinaryPath, "/usr/local/bin/7zz")
    }

    func testCompress_singleFile() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let inputFile = tempDir.appendingPathComponent("hello.txt")
        try "Hello World".write(to: inputFile, atomically: true, encoding: .utf8)
        let outputArchive = tempDir.appendingPathComponent("output.7z")

        try await service.compress(
            files: [inputFile], format: .sevenZ, level: 5,
            volumeSize: nil, password: nil, outputDir: tempDir
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputArchive.path))
    }

    func testExtract_7zArchive() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let inputFile = tempDir.appendingPathComponent("hello.txt")
        try "Hello World".write(to: inputFile, atomically: true, encoding: .utf8)

        let archive = tempDir.appendingPathComponent("test.7z")
        try await service.compress(
            files: [inputFile], format: .sevenZ, level: 5,
            volumeSize: nil, password: nil, outputDir: tempDir
        )

        let extractDir = tempDir.appendingPathComponent("extracted")
        try FileManager.default.createDirectory(at: extractDir, withIntermediateDirectories: true)

        try await service.extract(archive: archive, outputDir: extractDir, password: nil)

        let extractedFile = extractDir.appendingPathComponent("hello.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: extractedFile.path))
        let content = try String(contentsOf: extractedFile)
        XCTAssertEqual(content, "Hello World")
    }

    func testListContents() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let inputFile = tempDir.appendingPathComponent("list_test.txt")
        try "test content".write(to: inputFile, atomically: true, encoding: .utf8)

        let archive = tempDir.appendingPathComponent("list_test.7z")
        try await service.compress(
            files: [inputFile], format: .sevenZ, level: 5,
            volumeSize: nil, password: nil, outputDir: tempDir
        )

        let entries = try await service.listContents(archive: archive)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].name, "list_test.txt")
    }

    func testCancel_setsNotRunning() async throws {
        service.cancel()
        XCTAssertNotEqual(service.status, .running)
    }

    func testCompress_withVolumeSize() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let inputFile = tempDir.appendingPathComponent("bigfile.bin")
        let data = Data(repeating: 0xAA, count: 200_000)
        try data.write(to: inputFile)

        try await service.compress(
            files: [inputFile], format: .sevenZ, level: 1,
            volumeSize: "100k", password: nil, outputDir: tempDir
        )

        let vol1 = tempDir.appendingPathComponent("bigfile.bin.7z.001")
        XCTAssertTrue(FileManager.default.fileExists(atPath: vol1.path), "Volume file .001 should exist")
    }
}
