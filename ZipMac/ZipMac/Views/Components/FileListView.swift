import SwiftUI

struct FileListView: View {
    let files: [URL]
    let onRemove: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if files.isEmpty {
                Text("未选择文件")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(files.enumerated()), id: \.offset) { index, url in
                    HStack {
                        Image(systemName: url.hasDirectoryPath ? "folder.fill" : "doc.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Text(url.lastPathComponent)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Text(url.deletingLastPathComponent().path)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button {
                            onRemove(index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}
