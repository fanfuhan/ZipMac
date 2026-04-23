import SwiftUI

struct CompressView: View {
    @ObservedObject var service: SevenZipService
    @StateObject private var viewModel = CompressViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Mode toggle
            HStack {
                Spacer()
                Toggle(isOn: $viewModel.isAdvancedMode) {
                    Text("高级模式")
                        .font(.caption)
                }
                .toggleStyle(.switch)
                .controlSize(.small)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

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
                            Button("重新压缩") {
                                service.status = .idle
                            }
                            .buttonStyle(.bordered)
                        }
                    } else if viewModel.isAdvancedMode {
                        advancedContent
                    } else {
                        simpleContent
                    }
                }
                .padding(20)
            }
        }
    }

    // MARK: - Simple Mode

    private var simpleContent: some View {
        VStack(spacing: 20) {
            if viewModel.selectedFiles.isEmpty {
                DropZoneView(
                    title: "拖拽文件到此处",
                    subtitle: "或点击选择文件",
                    onDrop: { urls in
                        for url in urls { viewModel.addFile(url) }
                    },
                    onTap: { chooseFiles() }
                )
            } else {
                FileListView(files: viewModel.selectedFiles) { index in
                    viewModel.removeFile(at: index)
                }
            }

            HStack(spacing: 12) {
                Picker("", selection: $viewModel.format) {
                    ForEach(CompressionFormat.allCases) { fmt in
                        Text(fmt.displayName).tag(fmt)
                    }
                }
                .frame(width: 120)

                Button {
                    compress(with: viewModel.format)
                } label: {
                    Label("压缩", systemImage: "archivebox.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.selectedFiles.isEmpty)

                if !viewModel.selectedFiles.isEmpty {
                    Button {
                        chooseFiles()
                    } label: {
                        Label("添加", systemImage: "plus")
                    }
                    .buttonStyle(.bordered)

                    Button("清除") {
                        viewModel.clearFiles()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    // MARK: - Advanced Mode

    private var advancedContent: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("已选文件")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if viewModel.selectedFiles.isEmpty {
                    DropZoneView(
                        title: "拖拽文件到此处",
                        subtitle: "或点击选择文件",
                        onDrop: { urls in
                            for url in urls { viewModel.addFile(url) }
                        },
                        onTap: { chooseFiles() }
                    )
                } else {
                    FileListView(files: viewModel.selectedFiles) { index in
                        viewModel.removeFile(at: index)
                    }
                }
            }

            Grid {
                GridRow {
                    LabeledContent("压缩格式") {
                        Picker("", selection: $viewModel.format) {
                            ForEach(CompressionFormat.allCases) { fmt in
                                Text(fmt.displayName).tag(fmt)
                            }
                        }
                        .frame(width: 120)
                    }

                    LabeledContent("压缩级别") {
                        Picker("", selection: $viewModel.level) {
                            Text("极速 (1)").tag(1)
                            Text("快速 (3)").tag(3)
                            Text("标准 (5)").tag(5)
                            Text("最大 (7)").tag(7)
                            Text("极限 (9)").tag(9)
                        }
                        .frame(width: 120)
                    }
                }

                GridRow {
                    LabeledContent("分卷大小") {
                        TextField("例如: 100m, 1g", text: $viewModel.volumeSize)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                    }
                    LabeledContent("") {
                        Text("必须带单位：b/k/m/g")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    if viewModel.format.supportsEncryption {
                        LabeledContent("密码") {
                            SecureField("留空则不加密", text: $viewModel.password)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 120)
                        }
                    } else {
                        LabeledContent("密码") {
                            Text("此格式不支持加密")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            if !viewModel.volumeSize.isEmpty && !viewModel.isValidVolumeSize(viewModel.volumeSize) {
                Text("分卷大小格式无效，必须带单位（如 100m、1g）")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            HStack {
                Spacer()
                Button("开始压缩") {
                    compress(with: viewModel.format)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.selectedFiles.isEmpty || (!viewModel.isValidVolumeSize(viewModel.volumeSize)))
            }
        }
    }

    // MARK: - Actions

    private func compress(with format: CompressionFormat) {
        viewModel.format = format
        let outputDir = viewModel.selectedFiles.first?.deletingLastPathComponent() ?? .homeDirectory
        Task {
            do {
                try await viewModel.compress(service: service, outputDir: outputDir)
            } catch {
                service.errorMessage = error.localizedDescription
                service.status = .failed
            }
        }
    }

    private func chooseFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        if panel.runModal() == .OK {
            for url in panel.urls { viewModel.addFile(url) }
        }
    }
}
