import SwiftUI

struct ExtractView: View {
    @ObservedObject var service: SevenZipService
    @StateObject private var viewModel = ExtractViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    if service.status == .running || service.status == .completed || service.status == .failed {
                        OperationProgressView(
                            progress: service.progress,
                            status: service.status,
                            currentFile: service.currentFile,
                            errorMessage: service.errorMessage
                        ) {
                            viewModel.cancel(service: service)
                        }

                        if service.status == .completed || service.status == .failed {
                            Button("重新解压") {
                                service.status = .idle
                            }
                            .buttonStyle(.bordered)
                        }
                    } else if let archive = viewModel.selectedArchive {
                        archiveSelectedContent(archive)
                    } else {
                        DropZoneView(
                            title: "拖拽压缩包到此处",
                            subtitle: "支持 7z, ZIP, RAR 等 40+ 种格式",
                            onDrop: { urls in
                                if let url = urls.first { viewModel.setArchive(url) }
                            }
                        )
                    }
                }
                .padding(20)
            }
        }
    }

    private func archiveSelectedContent(_ archive: URL) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "doc.zipper.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading) {
                    Text(archive.lastPathComponent)
                        .font(.headline)
                    Text(archive.deletingLastPathComponent().path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("更换文件") {
                    viewModel.clearArchive()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            SecureField("密码（加密文件请输入）", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)

            if !viewModel.entries.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("压缩包内容")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ForEach(viewModel.entries.prefix(20)) { entry in
                        HStack {
                            Image(systemName: entry.isDirectory ? "folder.fill" : "doc.fill")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            Text(entry.name)
                                .font(.caption)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            if !entry.isDirectory {
                                Text(ByteCountFormatter.string(fromByteCount: entry.size, countStyle: .file))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    if viewModel.entries.count > 20 {
                        Text("还有 \(viewModel.entries.count - 20) 个文件...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button {
                extractArchive()
            } label: {
                Label("解压到当前目录", systemImage: "arrow.down.doc.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.isReadyToExtract)
        }
    }

    private func extractArchive() {
        guard let archive = viewModel.selectedArchive else { return }
        let outputDir = archive.deletingLastPathComponent()
        Task {
            try? await viewModel.extract(service: service, outputDir: outputDir)
        }
    }
}
