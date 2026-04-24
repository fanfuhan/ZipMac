# ZipMac

ZipMac 是一款 macOS 原生压缩/解压工具，基于 [7-Zip](https://www.7-zip.org/) 命令行工具 `7zz` 提供简洁的图形界面。

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2013.0%2B-blue" alt="Platform">
  <img src="https://img.shields.io/badge/swift-6.0-orange" alt="Swift">
  <img src="https://img.shields.io/badge/engine-7--Zip%2026.00-green" alt="Engine">
</p>

## 功能特性

- **压缩** — 支持多种格式，可选密码加密、分卷压缩和 1–9 级压缩
- **解压** — 支持密码解压，自动处理嵌套格式（如 `.tar.gz`）
- **预览** — 解压前可浏览档案内文件列表及大小
- **实时进度** — 操作过程显示百分比和当前处理文件名
- **拖放** — 支持拖拽文件/档案到窗口
- **简单 / 高级模式** — 压缩界面提供双模式切换，满足不同使用场景

## 系统要求

- macOS 13.0 (Ventura) 或更高版本
- Xcode 16+（编译需要 Swift 6.0）

## 支持的格式

| 格式 | 文件扩展名 | 加密 | 压缩 | 备注 |
|------|-----------|------|------|------|
| 7z | `.7z` | ✅ | ✅ | |
| ZIP | `.zip` | ✅ | ✅ | |
| GZIP | `.gz` | ❌ | ✅ | |
| BZIP2 | `.bz2` | ❌ | ✅ | |
| TAR | `.tar` | ❌ | ✅ | |
| TAR.GZ | `.tar.gz` | ❌ | ✅ | 两步压缩：先 tar 再 gzip |
| XZ | `.xz` | ❌ | ✅ | |
| WIM | `.wim` | ❌ | ✅ | |

所有格式均支持解压。

## 项目结构

```
ZipMac/
├── project.yml                 # XcodeGen 项目描述文件
├── ZipMac.xcodeproj/           # Xcode 项目（由 project.yml 生成）
├── ZipMacTests/                # 单元测试
└── ZipMac/
    ├── App/
    │   └── ZipMacApp.swift     # @main 应用入口，处理 7zz 二进制初始化
    ├── Info.plist
    ├── ZipMac.entitlements
    ├── Models/
    │   ├── CompressionFormat.swift  # 压缩格式枚举
    │   ├── ArchiveEntry.swift       # 档案内文件条目模型
    │   └── AppError.swift           # 错误类型与 7zz 退出码映射
    ├── Services/
    │   ├── SevenZipService.swift    # 7zz 进程封装（压缩/解压/列表/进度推送）
    │   └── OutputParser.swift       # 7zz stdout 解析器
    ├── ViewModels/
    │   ├── CompressViewModel.swift  # 压缩页状态管理
    │   └── ExtractViewModel.swift   # 解压页状态管理
    ├── Views/
    │   ├── MainWindowView.swift     # 主导航窗口（NavigationSplitView）
    │   ├── CompressView.swift       # 压缩页 UI
    │   ├── ExtractView.swift        # 解压页 UI
    │   ├── SettingsView.swift       # 设置页 UI
    │   └── Components/
    │       ├── DropZoneView.swift        # 拖放区域组件
    │       ├── FileListView.swift        # 文件列表组件
    │       └── OperationProgressView.swift # 进度展示组件
    └── Resources/
        └── 7zz                   # 7-Zip 命令行二进制文件
```

## 架构

```
SwiftUI Views  →  ViewModels  →  SevenZipService  →  Process(7zz 子进程)
                                     ↕
                                OutputParser ← stdout/stderr
```

三层设计：

- **View 层** — SwiftUI 视图，使用 MVVM 模式，`MainWindowView` 作为根视图，通过 `NavigationSplitView` 提供压缩/解压/设置三个标签页
- **ViewModel 层** — `@MainActor ObservableObject`，管理 UI 状态，通过 `SevenZipServiceProtocol` 协议调用服务层（便于单元测试 mock）
- **Service 层** — `SevenZipService` 封装 `Process` 调用 `7zz` 二进制，通过 `@Published` 属性发布 `progress`、`status`、`currentFile`、`errorMessage`

## 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/fanfuhan/ZipMac.git
cd ZipMac
```

### 2. 生成 Xcode 项目（可选）

项目使用 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 管理项目文件。如果修改了 `project.yml`，需要重新生成：

```bash
brew install xcodegen
cd ZipMac && xcodegen generate
```

> 仓库已包含生成的 `ZipMac.xcodeproj`，可直接用 Xcode 打开，无需执行此步骤。

### 3. 编译运行

**方式一：Xcode**

```bash
open ZipMac/ZipMac.xcodeproj
```

选择 `ZipMac` scheme，按 `Cmd+R` 运行。

**方式二：命令行**

```bash
xcodebuild -project ZipMac/ZipMac.xcodeproj -scheme ZipMac build
```

编译产物位于 `~/Library/Developer/Xcode/DerivedData/ZipMac-*/Build/Products/Debug/ZipMac.app`。

### 4. 打包 DMG

```bash
# 先 archive
xcodebuild -project ZipMac/ZipMac.xcodeproj -scheme ZipMac archive \
  -archivePath ZipMac.xcarchive

# 创建 .app 目录并打包为 DMG
mkdir -p dist
cp -R ZipMac.xcarchive/Products/Applications/ZipMac.app dist/
hdiutil create -volname ZipMac -srcfolder dist -ov -format UDZO ZipMac.dmg
```

## 运行测试

```bash
# 运行全部测试
xcodebuild -project ZipMac/ZipMac.xcodeproj -scheme ZipMac test

# 运行单个测试类
xcodebuild -project ZipMac/ZipMac.xcodeproj -scheme ZipMac test \
  -only-testing:ZipMacTests/OutputParserTests

# 运行单个测试方法
xcodebuild -project ZipMac/ZipMac.xcodeproj -scheme ZipMac test \
  -only-testing:ZipMacTests/OutputParserTests/testParseProgress_percentageOnly
```

> **注意**：`SevenZipServiceTests` 需要 `7zz` 二进制文件位于项目根目录下的 `/Users/fh.fan/Desktop/zip/7zz`，其他测试类（`OutputParserTests`、`CompressViewModelTests`、`ExtractViewModelTests`）为纯单元测试，无外部依赖。

## 使用说明

### 压缩文件

1. 切换到 **压缩** 标签页
2. 将文件/文件夹拖入拖放区域，或点击区域打开文件选择器
3. **简单模式**：选择格式后直接压缩
4. **高级模式**：可配置压缩级别（1-9）、分卷大小（如 `100m`、`1g`）、密码
5. 点击"压缩"按钮，等待进度条完成

### 解压文件

1. 切换到 **解压** 标签页
2. 将档案文件拖入拖放区域
3. 界面会显示档案内的文件列表（最多 20 个）及大小
4. 如有密码保护请输入密码
5. 点击"解压到当前目录"，档案将被解压到**原档案所在的同一目录**下

### 设置

- **默认压缩格式**：设置压缩页的默认选中格式
- **默认压缩级别**：设置压缩页的默认压缩级别（1-9）

设置通过 `UserDefaults` 持久化，应用重启后依然有效。

## 技术要点

- **7zz 二进制部署**：首次启动时，应用将内置的 `7zz` 二进制复制到 `~/Library/Application Support/ZipMac/7zz` 并设置可执行权限
- **进度解析**：通过 `-bsp1` 标志调用 `7zz`，使其向 stdout 输出进度信息，`OutputParser` 使用正则 `/^\s*(\d+)%\s*(.*)/` 提取百分比和文件名
- **两步格式处理**：`.tar.gz` 格式先 tar 归档，再 gzip 压缩；解压时先 gunzip 再解 tar，中间文件自动清理
- **并发模型**：`SevenZipService` 和 ViewModel 均为 `@MainActor` 隔离，确保 `@Published` 属性安全地在主线程更新
- **取消操作**：调用 `Process.terminate()` 终止子进程，状态重置为空闲

## 技术栈

- [Swift](https://swift.org/) 6.0
- [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- [7-Zip](https://www.7-zip.org/) 26.00
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)（项目生成）

## 许可证

本项目基于 GNU LGPL 许可证发布，与 7-Zip 保持一致。

---

Made with ❤️ for macOS
