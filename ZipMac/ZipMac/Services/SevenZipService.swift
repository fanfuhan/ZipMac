import Foundation

@MainActor
protocol SevenZipServiceProtocol: AnyObject {
    var progress: Double { get }
    var status: OperationStatus { get }
    var currentFile: String? { get }
    var errorMessage: String? { get }

    func compress(files: [URL], format: CompressionFormat, level: Int, volumeSize: String?, password: String?, outputDir: URL) async throws
    func extract(archive: URL, outputDir: URL, password: String?) async throws
    func listContents(archive: URL) async throws -> [ArchiveEntry]
    func cancel()
}

@MainActor
class SevenZipService: ObservableObject, SevenZipServiceProtocol {

    @Published var progress: Double = 0
    @Published var status: OperationStatus = .idle
    @Published var currentFile: String?
    @Published var errorMessage: String?

    let resolvedBinaryPath: String
    private var currentProcess: Process?

    init(binaryPath: String) {
        self.resolvedBinaryPath = binaryPath
    }

    convenience init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appSupportBinary = appSupport.appendingPathComponent("ZipMac/7zz").path

        if FileManager.default.fileExists(atPath: appSupportBinary) {
            self.init(binaryPath: appSupportBinary)
        } else if let bundlePath = Bundle.main.path(forResource: "7zz", ofType: nil) {
            self.init(binaryPath: bundlePath)
        } else {
            self.init(binaryPath: "7zz")
        }
    }

    func compress(files: [URL], format: CompressionFormat, level: Int = 5, volumeSize: String? = nil, password: String? = nil, outputDir: URL) async throws {
        guard FileManager.default.fileExists(atPath: resolvedBinaryPath) else {
            throw AppError.binaryNotFound
        }

        let archiveName = files.count == 1
            ? files[0].deletingPathExtension().lastPathComponent + "." + format.fileExtension
            : "archive." + format.fileExtension
        let archivePath = outputDir.appendingPathComponent(archiveName)

        var args = ["a", "-t\(format.flagValue)", "-mx\(level)", "-bsp1"]

        if let volumeSize { args.append("-v\(volumeSize)") }
        if let password { args.append("-p\(password)") }

        args.append(archivePath.path)
        args.append(contentsOf: files.map { $0.path })

        try await runProcess(arguments: args)
    }

    func extract(archive: URL, outputDir: URL, password: String? = nil) async throws {
        guard FileManager.default.fileExists(atPath: archive.path) else {
            throw AppError.archiveNotFound(archive.path)
        }

        var args = ["x", "-o\(outputDir.path)", "-bsp1", "-y"]
        if let password { args.append("-p\(password)") }
        args.append(archive.path)

        try await runProcess(arguments: args)
    }

    func listContents(archive: URL) async throws -> [ArchiveEntry] {
        guard FileManager.default.fileExists(atPath: archive.path) else {
            throw AppError.archiveNotFound(archive.path)
        }

        let args = ["l", archive.path]
        let output = try await runProcessForOutput(arguments: args)
        return OutputParser.parseArchiveEntries(output)
    }

    func cancel() {
        currentProcess?.terminate()
        status = .idle
        currentProcess = nil
    }

    private func runProcess(arguments: [String]) async throws {
        status = .running
        progress = 0
        currentFile = nil
        errorMessage = nil

        let process = Process()
        process.executableURL = URL(fileURLWithPath: resolvedBinaryPath)
        process.arguments = arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        stdoutPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            let output = String(data: data, encoding: .utf8) ?? ""

            for line in output.components(separatedBy: "\n") {
                if OutputParser.isCompletion(line) {
                    Task { @MainActor in self?.progress = 1.0 }
                }
                if let result = OutputParser.parseProgress(line) {
                    Task { @MainActor in
                        self?.progress = result.progress
                        self?.currentFile = result.currentFile
                    }
                }
            }
        }

        try process.run()
        currentProcess = process

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.global().async {
                process.waitUntilExit()
                continuation.resume()
            }
        }

        currentProcess = nil

        if process.terminationStatus == 0 {
            status = .completed
        } else {
            let error = AppError.from(exitCode: process.terminationStatus)
            errorMessage = error.errorDescription
            status = .failed
            throw error
        }
    }

    private func runProcessForOutput(arguments: [String]) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: resolvedBinaryPath)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        try process.run()

        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw AppError.from(exitCode: process.terminationStatus)
        }

        return String(data: outputData, encoding: .utf8) ?? ""
    }
}
