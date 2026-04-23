import Foundation

@MainActor
class CompressViewModel: ObservableObject {
    @Published var selectedFiles: [URL] = []
    @Published var format: CompressionFormat = .sevenZ
    @Published var level: Int = 5
    @Published var volumeSize: String = ""
    @Published var password: String = ""
    @Published var isAdvancedMode: Bool = false

    private var defaultsObserver: (any NSObjectProtocol)?

    init() {
        loadDefaults()
        observeDefaults()
    }

    nonisolated deinit {
        // Observer cleanup happens via NotificationCenter's weak reference;
        // no manual removal needed from nonisolated context.
    }

    private func loadDefaults() {
        let storedFormat = UserDefaults.standard.string(forKey: "defaultFormat") ?? "7z"
        format = CompressionFormat(rawValue: storedFormat) ?? .sevenZ
        let storedLevel = UserDefaults.standard.integer(forKey: "defaultLevel")
        level = storedLevel > 0 ? storedLevel : 5
    }

    private func observeDefaults() {
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.loadDefaults()
            }
        }
    }

    func addFile(_ url: URL) {
        if !selectedFiles.contains(url) {
            selectedFiles.append(url)
        }
    }

    func removeFile(at index: Int) {
        guard selectedFiles.indices.contains(index) else { return }
        selectedFiles.remove(at: index)
    }

    func clearFiles() {
        selectedFiles.removeAll()
    }

    var defaultOutputName: String {
        if selectedFiles.count == 1 {
            let name = selectedFiles[0].deletingPathExtension().lastPathComponent
            return "\(name).\(format.fileExtension)"
        }
        return "archive.\(format.fileExtension)"
    }

    func isValidVolumeSize(_ input: String) -> Bool {
        guard !input.isEmpty else { return true }
        let pattern = /^\d+[bkmg]?$/
        return input.lowercased().firstMatch(of: pattern) != nil
    }

    func compress(service: SevenZipServiceProtocol, outputDir: URL) async throws {
        try await service.compress(
            files: selectedFiles,
            format: format,
            level: level,
            volumeSize: volumeSize.isEmpty ? nil : volumeSize,
            password: password.isEmpty ? nil : password,
            outputDir: outputDir
        )
    }

    func cancel(service: SevenZipServiceProtocol) {
        service.cancel()
    }
}
