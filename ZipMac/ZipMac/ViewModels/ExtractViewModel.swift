import Foundation

@MainActor
class ExtractViewModel: ObservableObject {
    @Published var selectedArchive: URL?
    @Published var password: String = ""
    @Published var entries: [ArchiveEntry] = []

    func setArchive(_ url: URL) {
        selectedArchive = url
    }

    func clearArchive() {
        selectedArchive = nil
        entries = []
        password = ""
    }

    var isReadyToExtract: Bool {
        selectedArchive != nil
    }

    func extract(service: SevenZipServiceProtocol, outputDir: URL) async throws {
        guard let archive = selectedArchive else { return }
        try await service.extract(
            archive: archive,
            outputDir: outputDir,
            password: password.isEmpty ? nil : password
        )
    }

    func loadContents(service: SevenZipServiceProtocol) async throws {
        guard let archive = selectedArchive else { return }
        entries = try await service.listContents(archive: archive)
    }

    func cancel(service: SevenZipServiceProtocol) {
        service.cancel()
    }
}
