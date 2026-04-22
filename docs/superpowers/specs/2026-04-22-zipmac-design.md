# ZipMac — macOS 解压缩桌面应用设计文档

## 概述

基于 7zip for mac（7zz 二进制）扩展的 macOS 原生解压缩桌面应用，提供压缩、分卷压缩、解压功能，界面简约美观，兼顾普通用户和进阶用户。

## 技术选型

| 项目 | 选择 |
|------|------|
| GUI 框架 | SwiftUI |
| 最低系统版本 | macOS 13.0 (Ventura) |
| 压缩引擎 | 内嵌 7zz 二进制（子进程调用） |
| 架构模式 | MVVM |
| 编程语言 | Swift 5.9+ |

## 架构方案：SwiftUI + 内嵌 7zz 子进程

将预编译的 `7zz` 可执行文件打包进 app bundle，SwiftUI 界面通过 `Process` 调用 7zz 命令行，解析 stdout 获取进度和结果。

### 选择理由

- 最快速实现，无需编译 7zip C++ 源码
- 完整格式支持（7z 创建 + 40+ 种解压格式）
- 分卷压缩 `-v` 开关开箱即用
- 7zip 升级只需替换二进制文件
- 无需处理 C++ 互操作

### 三层架构

```
UI 层（SwiftUI）         → 主窗口 · 压缩视图 · 解压视图 · 设置视图
服务层（SevenZipService） → 压缩管理 · 解压管理 · 进度回调 · 错误处理 · 分卷逻辑
引擎层（7zz 子进程）      → 7zz 可执行文件，通过 Process 调用
```

## UI 设计

### 设计风格

macOS 原生风格，类似 Finder 的简洁界面。

### 简单模式（默认）

- 左侧导航栏：压缩 / 解压 / 设置
- 主体区域：拖拽文件区 + 快捷按钮（"压缩为 7z" / "压缩为 ZIP"）
- 一键操作，零配置

### 高级模式（切换后）

- 保留左侧导航
- 显示已选文件列表
- 参数网格：压缩格式 / 压缩级别 / 分卷大小 / 密码
- 分卷大小支持 `100m`、`1g` 等写法（对应 7zip 的 `-v` 参数）

### 解压视图

- 拖入压缩包 → 自动检测格式 → 选择解压目录 → 一键解压

## 数据流

```
SwiftUI 视图 → SevenZipService → Process(7zz) → 7zz 子进程
7zz 子进程 → stdout/stderr → OutputParser → 进度/状态 @Published → SwiftUI 自动刷新
```

## 核心类设计

### SevenZipService（服务层核心）

```swift
class SevenZipService: ObservableObject {
    @Published var progress: Double          // 0.0 ~ 1.0
    @Published var status: OperationStatus   // .idle / .running / .completed / .failed
    @Published var currentFile: String       // 当前处理的文件名
    @Published var errorMessage: String?

    func compress(files:, format:, level:, volumeSize:, password:, outputDir:)
    func extract(archive:, outputDir:, password:)
    func listContents(archive:) -> [ArchiveEntry]
    func cancel()
}
```

### OutputParser（输出解析器）

解析 7zz 的 stdout 输出。使用 `-bsp1` 开关让 7zz 输出进度百分比到 stdout。

默认进度格式：`12%  # 正在压缩 file.txt`

解析正则：`/^(\d+)%\s*#?\s*(.*)$/`

### 7zz 命令行映射

| 操作 | 命令 |
|------|------|
| 压缩 | `7zz a -t{format} -mx{level} [-v{size}] [-p{pwd}] output.7z input1 input2 ...` |
| 解压 | `7zz x -o{outputDir} [-p{pwd}] archive.7z` |
| 列表 | `7zz l archive.7z` |
| 取消 | `Process.terminate()` |

## 项目文件结构

```
ZipMac/
├── ZipMac.xcodeproj
├── ZipMac/
│   ├── App/
│   │   ├── ZipMacApp.swift            // @main 入口
│   │   └── AppDelegate.swift
│   ├── Views/
│   │   ├── MainWindowView.swift       // 主窗口
│   │   ├── CompressView.swift         // 压缩视图（简单+高级）
│   │   ├── ExtractView.swift          // 解压视图
│   │   ├── SettingsView.swift         // 设置视图
│   │   └── Components/
│   │       ├── DropZoneView.swift     // 拖拽区域组件
│   │       ├── ProgressView.swift     // 进度条组件
│   │       └── FileListView.swift     // 文件列表组件
│   ├── ViewModels/
│   │   ├── CompressViewModel.swift
│   │   └── ExtractViewModel.swift
│   ├── Services/
│   │   ├── SevenZipService.swift      // 7zz 调用核心
│   │   └── OutputParser.swift         // 输出解析
│   └── Models/
│       ├── ArchiveEntry.swift         // 压缩包内条目模型
│       ├── CompressionFormat.swift    // 格式枚举
│       └── AppError.swift             // 错误类型定义
└── Resources/
    └── 7zz                           // 内嵌的 7zz 二进制
```

## 7zz 内嵌方式

- 将 `7zz` 二进制放入 Xcode 项目的 Resources 目录，勾选 target membership
- 运行时定位：`Bundle.main.path(forResource: "7zz", ofType: nil)`
- 首次启动：将 7zz 复制到 Application Support 目录并 `chmod +x`，后续直接使用该副本
- 原因：macOS 签名机制可能限制直接执行 bundle 内的二进制，复制到 Application Support 更可靠

## 错误处理

### AppError 枚举

```swift
enum AppError: LocalizedError {
    case binaryNotFound           // 7zz 未找到
    case processLaunchFailed      // 子进程启动失败
    case archiveNotFound          // 压缩包不存在
    case outputDirectoryInvalid   // 输出目录无效
    case wrongPassword            // 密码错误
    case diskFull                 // 磁盘空间不足
    case userCancelled            // 用户取消
    case unknown(exitCode: Int)   // 未知错误（附退出码）
}
```

### 7zz 退出码映射

| 退出码 | 含义 |
|--------|------|
| 0 | 成功 |
| 1 | 警告（非致命错误） |
| 2 | 致命错误 |
| 7 | 命令行错误 |
| 8 | 内存不足 |
| 255 | 用户中断（Ctrl+C） |

## 支持的压缩格式

### 创建格式（7 种）

7z, BZIP2, GZIP, TAR, WIM, XZ, ZIP

### 解压格式（40+ 种）

7z, ZIP, GZIP, BZIP2, TAR, XZ, RAR, ISO, DMG, CAB, ARJ, LZH, CHM, CPIO, RPM, DEB, LZMA, SQUASHFS, NTFS, FAT, HFS, APFS, VHD, VMDK 等

## 功能范围

### 核心功能

- 压缩文件/文件夹为 7z / ZIP 格式
- 分卷压缩（自定义分卷大小）
- 解压 40+ 种格式
- 密码加密压缩 / 解压
- 查看压缩包内容列表
- 取消正在进行的操作

### 高级模式功能

- 选择压缩格式（7z/ZIP/TAR/GZIP/BZIP2/XZ）
- 选择压缩级别（1-9）
- 设置分卷大小
- 设置密码

### 不在范围内

- 创建 RAR 格式（7zip 不支持）
- 更新已有分卷压缩包
- 压缩包内文件浏览/编辑
- 系统右键菜单集成
