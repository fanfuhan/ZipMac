import SwiftUI

struct OperationProgressView: View {
    let progress: Double
    let status: OperationStatus
    let currentFile: String?
    let errorMessage: String?
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(status == .running ? "处理中..." : status == .completed ? "完成" : "失败")
                    .font(.headline)
                Spacer()
                if status == .running {
                    Button("取消") {
                        onCancel()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(.linear)

            HStack {
                if let file = currentFile {
                    Text(file)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
