import SwiftUI

struct MainWindowView: View {
    @StateObject private var service = SevenZipService(binaryPath: resolveBinaryPath())
    @State private var selectedTab: Tab = .compress

    enum Tab: String, CaseIterable, Identifiable {
        case compress = "压缩"
        case extract = "解压"
        case settings = "设置"

        var id: String { rawValue }
    }

    var body: some View {
        NavigationSplitView {
            List(Tab.allCases, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: icon(for: tab))
                    .tag(tab)
            }
            .navigationSplitViewColumnWidth(150)
        } detail: {
            switch selectedTab {
            case .compress:
                CompressView(service: service)
            case .extract:
                ExtractView(service: service)
            case .settings:
                SettingsView()
            }
        }
    }

    private func icon(for tab: Tab) -> String {
        switch tab {
        case .compress: return "archivebox.fill"
        case .extract: return "arrow.down.doc.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

private func resolveBinaryPath() -> String {
    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let appSupportBinary = appSupport.appendingPathComponent("ZipMac/7zz").path

    if FileManager.default.fileExists(atPath: appSupportBinary) {
        return appSupportBinary
    } else if let bundlePath = Bundle.main.path(forResource: "7zz", ofType: nil) {
        return bundlePath
    } else {
        return "7zz"
    }
}
