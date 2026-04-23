# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ZipMac is a macOS native archive utility built with SwiftUI. It wraps the 7-Zip `7zz` command-line binary (bundled as a resource) to provide compress, extract, and archive-listing operations. The UI is in Chinese (简体中文).

## Build & Test

This project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) — the Xcode project is generated from `ZipMac/project.yml`. If you modify `project.yml`, regenerate with:

```bash
cd ZipMac && xcodegen generate
```

Build and test via `xcodebuild`:

```bash
# Build
xcodebuild -project ZipMac/ZipMac.xcodeproj -scheme ZipMac build

# Run all tests
xcodebuild -project ZipMac/ZipMac.xcodeproj -scheme ZipMac test

# Run a single test class
xcodebuild -project ZipMac/ZipMac.xcodeproj -scheme ZipMac test -only-testing:ZipMacTests/OutputParserTests

# Run a single test method
xcodebuild -project ZipMac/ZipMac.xcodeproj -scheme ZipMac test -only-testing:ZipMacTests/OutputParserTests/testParseProgress_percentageOnly
```

**Test note:** `SevenZipServiceTests` require the `7zz` binary at `/Users/fh.fan/Desktop/zip/7zz`. Other test targets (`OutputParserTests`, `CompressViewModelTests`, `ExtractViewModelTests`) are pure unit tests with no external dependencies.

## Architecture

Three-layer design: **UI → Service → Engine**

```
SwiftUI Views  →  SevenZipService  →  Process(7zz subprocess)
                  OutputParser  ←──  stdout/stderr
```

- **UI Layer** (`Views/`): SwiftUI views using MVVM. `MainWindowView` is the root with a `NavigationSplitView` sidebar (compress/extract/settings tabs). A single shared `SevenZipService` instance is created in `MainWindowView` and passed to child views.
- **ViewModel Layer** (`ViewModels/`): `CompressViewModel` and `ExtractViewModel` are `@MainActor` `ObservableObject` classes that hold UI state and delegate operations to `SevenZipServiceProtocol`. The protocol enables testability via mocking.
- **Service Layer** (`Services/`): `SevenZipService` wraps `Process` calls to the `7zz` binary. It publishes `progress`, `status`, `currentFile`, and `errorMessage` via `@Published` properties. `OutputParser` parses `7zz` stdout for progress percentages and archive listings using regex.
- **Model Layer** (`Models/`): `CompressionFormat` enum (7 create formats), `ArchiveEntry` struct, `AppError` enum with 7zz exit-code mapping.

## Key Patterns

- **7zz binary setup**: On first launch, `ZipMacApp.setupBinary()` copies the bundled `7zz` to `~/Library/Application Support/ZipMac/7zz` and sets `0o755` permissions. `SevenZipService` resolves the binary path from App Support → Bundle → PATH fallback.
- **Progress tracking**: `7zz` is invoked with `-bsp1` flag to output progress to stdout. `OutputParser.parseProgress()` extracts `NN%` and optional filename from each line.
- **Swift 6 concurrency**: ViewModels and `SevenZipService` are `@MainActor`-isolated. `SevenZipServiceProtocol` is also `@MainActor`. Tests for these use `@MainActor` annotation.
- **Drag-and-drop**: `DropZoneView` handles file drops via `onDrop(of: [.fileURL])` and `NSItemProvider` with `public.file-url` type identifier.

## Configuration

- **Swift version**: 6.0
- **Minimum deployment**: macOS 13.0 (Ventura)
- **Bundle ID**: `com.zipmac.app`
- **Code signing**: ad-hoc (`CODE_SIGN_IDENTITY: "-"`)
