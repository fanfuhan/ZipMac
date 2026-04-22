import Foundation

enum OperationStatus: Equatable {
    case idle
    case running
    case completed
    case failed
}

enum AppError: LocalizedError {
    case binaryNotFound
    case processLaunchFailed(String)
    case archiveNotFound(String)
    case outputDirectoryInvalid(String)
    case wrongPassword
    case diskFull
    case userCancelled
    case unknown(exitCode: Int32)

    var errorDescription: String? {
        switch self {
        case .binaryNotFound:
            return "7zz binary not found."
        case .processLaunchFailed(let reason):
            return "Failed to launch 7zz: \(reason)"
        case .archiveNotFound(let path):
            return "Archive not found: \(path)"
        case .outputDirectoryInvalid(let path):
            return "Output directory is invalid: \(path)"
        case .wrongPassword:
            return "Wrong password or encrypted archive."
        case .diskFull:
            return "Not enough disk space."
        case .userCancelled:
            return "Operation cancelled."
        case .unknown(let code):
            return "Unknown error (exit code: \(code))"
        }
    }

    static func from(exitCode: Int32) -> AppError {
        switch exitCode {
        case 1: return .unknown(exitCode: exitCode)
        case 2: return .wrongPassword
        case 7: return .processLaunchFailed("Command line error")
        case 8: return .diskFull
        case 255: return .userCancelled
        default: return .unknown(exitCode: exitCode)
        }
    }
}
