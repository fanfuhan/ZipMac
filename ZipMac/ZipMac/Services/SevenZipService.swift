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
            status = .failed
            errorMessage = AppError.binaryNotFound.errorDescription
            throw AppError.binaryNotFound
        }

        if format.isTwoStep {
            try await compressTwoStep(files: files, format: format, level: level, outputDir: outputDir)
            return
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

    private func compressTwoStep(files: [URL], format: CompressionFormat, level: Int, outputDir: URL) async throws {
        // Step 1: create tar archive
        let tarName = files.count == 1
            ? files[0].deletingPathExtension().lastPathComponent + ".tar"
            : "archive.tar"
        let tarPath = outputDir.appendingPathComponent(tarName)

        let tarArgs = ["a", "-ttar", "-bsp1", tarPath.path] + files.map { $0.path }
        try await runProcess(arguments: tarArgs)

        // Step 2: compress tar with the outer format (gzip for tar.gz)
        guard let stepFormat = format.compressStepFormat else { return }
        let compressedName = tarName.replacingOccurrences(of: ".tar", with: ".\(format.fileExtension)")
        let compressedPath = outputDir.appendingPathComponent(compressedName)

        let compressArgs = ["a", "-t\(stepFormat.flagValue)", "-mx\(level)", "-bsp1", compressedPath.path, tarPath.path]
        try await runProcess(arguments: compressArgs)

        // Clean up intermediate tar file
        try? FileManager.default.removeItem(at: tarPath)
    }

    func extract(archive: URL, outputDir: URL, password: String? = nil) async throws {
        guard FileManager.default.fileExists(atPath: archive.path) else {
            throw AppError.archiveNotFound(archive.path)
        }

        let isNestedArchive = archive.pathExtension == "gz" && archive.deletingPathExtension().pathExtension == "tar"

        if isNestedArchive {
            try await extractNestedArchive(archive: archive, outputDir: outputDir, password: password)
            return
        }

        var args = ["x", "-o\(outputDir.path)", "-bsp1", "-y"]
        if let password { args.append("-p\(password)") }
        args.append(archive.path)

        try await runProcess(arguments: args)
    }

    private func extractNestedArchive(archive: URL, outputDir: URL, password: String?) async throws {
        // Step 1: decompress outer layer (e.g. gzip) to a temp directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        var step1Args = ["x", "-o\(tempDir.path)", "-bsp1", "-y"]
        if let password { step1Args.append("-p\(password)") }
        step1Args.append(archive.path)
        try await runProcess(arguments: step1Args)

        // Step 2: extract the inner tar archive to the final output directory
        let tarFiles = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        for tarFile in tarFiles {
            var step2Args = ["x", "-o\(outputDir.path)", "-bsp1", "-y"]
            if let password { step2Args.append("-p\(password)") }
            step2Args.append(tarFile.path)
            try await runProcess(arguments: step2Args)
        }

        // Clean up temp directory
        try? FileManager.default.removeItem(at: tempDir)
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

            for line in output.components(separatedBy: CharacterSet(charactersIn: "\r\n\u{08}")) {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                guard !trimmedLine.isEmpty else { continue }

                if OutputParser.isCompletion(trimmedLine) {
                    Task { @MainActor in self?.progress = 1.0 }
                }
                if let result = OutputParser.parseProgress(trimmedLine) {
                    Task { @MainActor in
                        self?.progress = result.progress
                        self?.currentFile = result.currentFile
                    }
                }
            }
        }

        do {
            try process.run()
        } catch {
            status = .failed
            errorMessage = AppError.processLaunchFailed(error.localizedDescription).errorDescription
            throw AppError.processLaunchFailed(error.localizedDescription)
        }

        currentProcess = process

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.global().async {
                process.waitUntilExit()
                continuation.resume()
            }
        }

        currentProcess = nil

        if process.terminationStatus == 0 {
            progress = 1.0
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
