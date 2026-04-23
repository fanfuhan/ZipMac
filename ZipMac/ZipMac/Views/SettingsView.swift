import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultFormat") private var defaultFormat = "7z"
    @AppStorage("defaultLevel") private var defaultLevel = 5

    var body: some View {
        Form {
            Section("默认压缩选项") {
                LabeledContent("默认格式") {
                    Picker("", selection: $defaultFormat) {
                        ForEach(CompressionFormat.allCases) { fmt in
                            Text(fmt.displayName).tag(fmt.rawValue)
                        }
                    }
                    .frame(width: 120)
                }

                LabeledContent("默认级别") {
                    Picker("", selection: $defaultLevel) {
                        Text("极速 (1)").tag(1)
                        Text("快速 (3)").tag(3)
                        Text("标准 (5)").tag(5)
                        Text("最大 (7)").tag(7)
                        Text("极限 (9)").tag(9)
                    }
                    .frame(width: 120)
                }
            }

            Section("关于") {
                LabeledContent("应用名称") { Text("ZipMac") }
                LabeledContent("版本") { Text("1.0.0") }
                LabeledContent("压缩引擎") { Text("7-Zip 26.00") }
                LabeledContent("许可证") {
                    Link("GNU LGPL", destination: URL(string: "https://www.7-zip.org/license.txt")!)
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
