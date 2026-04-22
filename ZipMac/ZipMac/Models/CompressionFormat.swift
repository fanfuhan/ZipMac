import Foundation

enum CompressionFormat: String, CaseIterable, Identifiable {
    case sevenZ = "7z"
    case zip = "zip"
    case gzip = "gzip"
    case bzip2 = "bzip2"
    case tar = "tar"
    case xz = "xz"
    case wim = "wim"

    var id: String { rawValue }

    /// File extension for the output archive
    var fileExtension: String {
        switch self {
        case .sevenZ: return "7z"
        case .zip: return "zip"
        case .gzip: return "gz"
        case .bzip2: return "bz2"
        case .tar: return "tar"
        case .xz: return "xz"
        case .wim: return "wim"
        }
    }

    /// 7zip -t flag value
    var flagValue: String { rawValue }

    /// Whether this format supports password encryption
    var supportsEncryption: Bool {
        switch self {
        case .sevenZ, .zip: return true
        default: return false
        }
    }

    /// User-facing display name
    var displayName: String {
        switch self {
        case .sevenZ: return "7z"
        case .zip: return "ZIP"
        case .gzip: return "GZIP"
        case .bzip2: return "BZIP2"
        case .tar: return "TAR"
        case .xz: return "XZ"
        case .wim: return "WIM"
        }
    }
}
