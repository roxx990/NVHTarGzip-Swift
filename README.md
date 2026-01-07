# NVHTarGzip-Swift

[![SwiftPM Compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-blue.svg)](https://github.com/yourusername/TarGzip)
[![Maintenance](https://img.shields.io/badge/maintenance-actively--developed-brightgreen.svg)](https://github.com/yourusername/TarGzip/graphs/commit-activity)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A **pure Swift** library for creating and extracting `.tar`, `.gz`, and `.tar.gz` (`.tgz`) archives on Apple platforms.

This project is a modern reimplementation inspired by the original [NVHTarGzip](https://github.com/nvh/NVHTarGzip) by Niels van Hoorn (last updated 2016). The original was written in Objective-C and provided excellent file-based tar/gzip handling with progress reporting for iOS apps.

**NVHTarGzip-Swift** brings the same powerful functionality into pure Swift, making it fully compatible with **Swift Package Manager (SPM)**, modern Apple platforms, and easy integration into any Swift project — while preserving the core design principles:

- Direct file-path operations (no loading entire archives into memory)
- Low memory footprint, ideal for large archives
- Built-in **progress tracking** via `Progress`
- Synchronous and asynchronous APIs
- No external dependencies beyond Apple's `Foundation` and built-in `zlib`

## Features

- Extract and create `.tar` archives
- Compress and decompress `.gz` files
- Combined `.tar.gz` / `.tgz` extraction and creation
- Synchronous and asynchronous methods with completion handlers
- Real-time progress reporting using `Progress` (perfect for UI progress bars)
- Handles directories, files, and standard USTAR tar format
- Works directly with file paths on disk
- Uses temporary files only during combined tar+gzip operations (automatically cleaned up)
- Pure Swift – no Objective-C bridging required

## Supported Platforms

- iOS 12.0+
- macOS 11+
- tvOS 13.0+
- watchOS 6.0+

(The code uses only cross-platform Foundation APIs and should work on earlier versions if you adjust the deployment target.)

## Installation

Add TarGzip as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/roxx990/TarGzip.git", from: "1.0.0")
]
```

Then add it to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["TarGzip"]
)
```
Or add it via Xcode:
File → Add Package Dependency → Enter the repository URL.

```swift
import TarGzip
```

## Usage

### Shared Instance

```swift
let tgz = NVHTarGzip.shared
```

### Extract a .tar.gz File (Asynchronous)

```swift
tgz.unTarGzipFile(atPath: "/path/to/archive.tar.gz", 
                  toPath: "/path/to/destination/folder") { error in
    if let error = error {
        print("Extraction failed: \(error)")
    } else {
        print("Extraction completed successfully!")
    }
}
```

### Create a .tar.gz Archive (Asynchronous)

```swift
tgz.tarGzipFile(atPath: "/path/to/source/folder", 
                toPath: "/path/to/archive.tar.gz") { error in
    if let error = error {
        print("Compression failed: \(error)")
    } else {
        print("Archive created successfully!")
    }
}
```

### Individual Operations (Synchronous Examples)

```swift
// Ungzip
try tgz.unGzipFile(atPath: "file.gz", toPath: "file")

// Untar
try tgz.unTarFile(atPath: "archive.tar", toPath: "destination/")

// Gzip
try tgz.gzipFile(atPath: "file", toPath: "file.gz")

// Tar
try tgz.tarFile(atPath: "folder/", toPath: "archive.tar")
```

### Progress Tracking

All operations automatically set up an internal NVHProgress instance. To observe progress in your UI:

```swift
let progress = Progress(totalUnitCount: 100)

// Make this the current progress before starting the operation
progress.becomeCurrent(withPendingUnitCount: 100)

tgz.unTarGzipFile(atPath: source, toPath: dest) { error in
    progress.resignCurrent()
    // Handle completion
}

// Observe progress
let observation = progress.observe(\.fractionCompleted) { progress, _ in
    print("Progress: \(Int(progress.fractionCompleted * 100))%")
}
```

## Differences from the Original NVHTarGzip

| Feature              | Original (Objective-C)          | This Version (Pure Swift)      |
|----------------------|---------------------------------|--------------------------------|
| Language             | Objective-C                     | 100% Swift                     |
| Package Manager      | CocoaPods                       | Swift Package Manager          |
| Progress Reporting   | NSProgress (KVO)                | Progress (modern observation)  |
| Memory Usage         | Low (file-based)                | Low (file-based)               |
| Async APIs           | Completion blocks               | Completion handlers            |
| Last Updated         | 2016                            | 2026+ (actively maintainable)  |
| Dependencies         | None                            | None (uses built-in zlib)      |

## License
*NVHTarGzip-Swift* is available under the *MIT license*. See the `LICENSE` file for more info.

Inspired by and based on the design of nvh/NVHTarGzip.
Rebuilt from the ground up in pure Swift for modern Swift development.
