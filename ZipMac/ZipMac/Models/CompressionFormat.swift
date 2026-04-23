import Foundation

enum CompressionFormat: String, CaseIterable, Identifiable {
    case sevenZ = "7z"
    case zip = "zip"
    case gzip = "gzip"
    case bzip2 = "bzip2"
    case tar = "tar"
    case xz = "xz"
    case tarGz = "tar.gz"
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
        case .tarGz: return "tar.gz"
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
        case .tarGz: return "TAR.GZ"
        case .xz: return "XZ"
        case .wim: return "WIM"
        }
    }

    /// Whether this format requires a two-step process (tar then compress)
    var isTwoStep: Bool {
        switch self {
        case .tarGz: return true
        default: return false
        }
    }

    /// The tar compression step's format for two-step formats
    var compressStepFormat: CompressionFormat? {
        switch self {
        case .tarGz: return .gzip
        default: return nil
        }
    }
}
