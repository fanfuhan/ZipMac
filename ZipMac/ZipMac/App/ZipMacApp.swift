import SwiftUI

@main
struct ZipMacApp: App {
    init() {
        setupBinary()
    }

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .frame(minWidth: 600, minHeight: 400)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 700, height: 500)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }

    private func setupBinary() {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let zipMacDir = appSupport.appendingPathComponent("ZipMac")
        let destBinary = zipMacDir.appendingPathComponent("7zz")

        if fm.fileExists(atPath: destBinary.path) { return }

        guard let bundlePath = Bundle.main.path(forResource: "7zz", ofType: nil) else { return }

        do {
            try fm.createDirectory(at: zipMacDir, withIntermediateDirectories: true)
            try fm.copyItem(atPath: bundlePath, toPath: destBinary.path)
            try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: destBinary.path)
        } catch {
            print("Failed to setup 7zz binary: \(error)")
        }
    }
}
