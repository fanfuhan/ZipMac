import Foundation

struct ArchiveEntry: Identifiable {
    let id = UUID()
    let name: String
    let size: Int64
    let compressedSize: Int64
    let isDirectory: Bool
    let modifiedDate: Date?
}
