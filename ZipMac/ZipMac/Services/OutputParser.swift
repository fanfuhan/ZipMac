import Foundation

struct OutputParser {

    struct ProgressResult {
        let progress: Double
        let currentFile: String?
    }

    /// Parse a single line of 7zz output for progress percentage.
    /// 7zz outputs lines like " 42%" or " 75%  document.pdf"
    static func parseProgress(_ line: String) -> ProgressResult? {
        let pattern = /^\s*(\d+)%\s*(.*)/
        guard let match = line.firstMatch(of: pattern) else { return nil }

        guard let percent = Double(match.1) else { return nil }
        let file = String(match.2).trimmingCharacters(in: .whitespaces)

        return ProgressResult(
            progress: percent / 100.0,
            currentFile: file.isEmpty ? nil : file
        )
    }

    /// Check if the output line indicates a successful completion
    static func isCompletion(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespaces) == "Everything is Ok"
    }

    /// Parse the full output of `7zz l` into structured ArchiveEntry objects
    static func parseArchiveEntries(_ output: String) -> [ArchiveEntry] {
        let lines = output.components(separatedBy: "\n")
        var entries: [ArchiveEntry] = []
        var inTable = false

        for line in lines {
            // Detect table separator line
            if line.contains("---") && line.contains("----") {
                if inTable {
                    // End of table
                    inTable = false
                } else {
                    // Start of table
                    inTable = true
                }
                continue
            }

            guard inTable else { continue }

            // Skip empty lines
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.count > 0 else { continue }

            // Date format: "2024-01-15 10:30:00"
            let datePattern = /^\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\s+/
            guard trimmed.firstMatch(of: datePattern) != nil else { continue }

            // Parse: date(19) attrs(5) size compressed name
            // Format: "2024-01-15 10:30:00 D....  0  0  folder/"
            let afterDate = trimmed.dropFirst(19).trimmingCharacters(in: .whitespaces)

            // Extract attributes (5 chars)
            let attrs = String(afterDate.prefix(5))
            let isDirectory = attrs.hasPrefix("D")

            // Parse remaining: size compressed name
            let afterAttrs = afterDate.dropFirst(5).trimmingCharacters(in: .whitespaces)
            let parts = afterAttrs.split(separator: " ", omittingEmptySubsequences: true)

            // We expect: size compressed name (at least 3 parts)
            // or: size name (2 parts, when compressed is not shown separately)
            guard parts.count >= 2 else { continue }

            let size: Int64
            let compressedSize: Int64
            let name: String

            if parts.count >= 3 {
                size = Int64(parts[0]) ?? 0
                compressedSize = Int64(parts[1]) ?? 0
                name = parts[2...].joined(separator: " ")
            } else {
                size = Int64(parts[0]) ?? 0
                compressedSize = 0
                name = parts[1...].joined(separator: " ")
            }

            // Parse date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let dateStr = String(trimmed.prefix(19))
            let modifiedDate = dateFormatter.date(from: dateStr)

            entries.append(ArchiveEntry(
                name: name,
                size: size,
                compressedSize: compressedSize,
                isDirectory: isDirectory,
                modifiedDate: modifiedDate
            ))
        }

        return entries
    }
}
