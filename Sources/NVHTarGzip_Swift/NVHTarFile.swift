//
//  NVHTarFile.swift
//  NVHTarGzip-Swift
//
//  Created by roxx990 on 07/01/2026.
//  Copyright © 2026 roxx990. All rights reserved.
//
//  A pure-Swift reimplementation of NVHTarGzip, supporting .tar, .gz, and .tar.gz archives
//  with progress tracking on Apple platforms.
//


import Foundation

public class NVHTarFile: NVHFile {
    private var completedVirtualUnitCount: Int64 = 0

    // MARK: - Unpacking (untar)

    func createFilesAndDirectories(atPath destinationPath: String) throws {
        setupProgress()
        try innerCreateFilesAndDirectories(atPath: destinationPath)
    }

    func createFilesAndDirectories(atPath destinationPath: String, completion: @escaping (Error?) -> Void) {
        setupProgress()
        DispatchQueue.global().async {
            do {
                try self.innerCreateFilesAndDirectories(atPath: destinationPath)
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }

    private func innerCreateFilesAndDirectories(atPath path: String) throws {
        updateProgressVirtualTotalUnitCountWithFileSize()

        let fileManager = FileManager.default
        try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)

        guard let fileHandle = FileHandle(forReadingAtPath: filePath) else {
            throw NSError(domain: TAR_ERROR_DOMAIN, code: TAR_ERROR_CODE_SOURCE_NOT_FOUND)
        }
        defer { try? fileHandle.close() }

        try createFilesAndDirectories(atPath: path, withTarObject: fileHandle, size: fileSize)

        updateProgressVirtualCompletedUnitCountWithTotal()
    }

    private func createFilesAndDirectories(atPath path: String, withTarObject object: FileHandle, size: UInt64) throws {
        let fileManager = FileManager.default
        var location: UInt64 = 0
        let blockSize = UInt64(TAR_BLOCK_SIZE)  // Cast once for reuse

        while location < size {
            updateProgressVirtualCompletedUnitCount(Int64(location))

            var blockCount: UInt64 = 1

            let type = type(forObject: object, atOffset: location)

            switch type {
            case "0", "\0":
                let name = name(forObject: object, atOffset: location)
                guard !name.isEmpty else { break }

                let filePath = path.appendingPathComponent(name)
                let objectSize = self.size(forObject: object, atOffset: location)

                // Calculate how many full blocks the file data occupies
                blockCount += (objectSize + blockSize - 1) / blockSize

                if name.lastPathComponent != name {
                    let directoryPath = filePath.deletingLastPathComponent
                    try fileManager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)
                }

                // Empty files are just headers with size 0
                if objectSize == 0 {
                    try Data().write(to: URL(fileURLWithPath: filePath))
                } else {
                    try writeFileData(forObject: object,
                                      atLocation: location + blockSize,
                                      withLength: objectSize,
                                      atPath: filePath)
                }

            case "5":
                let name = name(forObject: object, atOffset: location)
                let directoryPath = path.appendingPathComponent(name)
                try fileManager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)

            default:
                // Unsupported entry types – skip their data blocks
                let objectSize = self.size(forObject: object, atOffset: location)
                blockCount += (objectSize + blockSize - 1) / blockSize
            }

            // FIXED LINE: Use pre-casted blockSize
            location += blockCount * blockSize
        }
    }

    private func writeFileData(forObject object: FileHandle,
                               atLocation location: UInt64,
                               withLength length: UInt64,
                               atPath path: String) throws {
        FileManager.default.createFile(atPath: path, contents: nil)

        guard let destinationFile = FileHandle(forWritingAtPath: path) else {
            throw NSError(domain: TAR_ERROR_DOMAIN, code: TAR_ERROR_CODE_BAD_BLOCK)
        }
        defer { try? destinationFile.close() }

        try object.seek(toOffset: location)

        var remaining = length
        let blockSize = UInt64(TAR_BLOCK_SIZE)
        let maxChunk = UInt64(TAR_MAX_BLOCK_LOAD_IN_MEMORY) * blockSize

        while remaining > 0 {
            let readSize = min(remaining, maxChunk)
            if let data = try? object.read(upToCount: Int(readSize)) {
                try destinationFile.write(contentsOf: data)
            }
            remaining -= readSize
        }
    }

    private func type(forObject object: FileHandle, atOffset offset: UInt64) -> String {
        // Now, TAR_TYPE_POSITION is a UInt64 constant
        let location = offset + TAR_TYPE_POSITION  // No need for explicit casting now

        try? object.seek(toOffset: location)

        if let data = try? object.read(upToCount: 1), !data.isEmpty {
            let byte = data.withUnsafeBytes { $0.load(as: Int8.self) }
            if byte != 0 {
                return String(UnicodeScalar(UInt8(bitPattern: byte)))
            }
        }
        return "\0"
    }

    private func size(forObject object: FileHandle, atOffset offset: UInt64) -> UInt64 {
        // Now, TAR_SIZE_POSITION is a UInt64 constant
        let location = offset + TAR_SIZE_POSITION  // No need for explicit casting now

        try? object.seek(toOffset: location)

        guard let data = try? object.read(upToCount: Int(TAR_SIZE_SIZE)),
              !data.isEmpty else {
            return 0
        }

        if let str = String(data: data, encoding: .ascii) {
            let cleaned = str.replacingOccurrences(of: "\0", with: "").trimmingCharacters(in: .whitespaces)
            return UInt64(cleaned, radix: 8) ?? 0
        }

        return 0
    }

    private func name(forObject object: FileHandle, atOffset offset: UInt64) -> String {
        let location = offset + UInt64(TAR_NAME_POSITION)

        try? object.seek(toOffset: location)

        if let data = try? object.read(upToCount: Int(TAR_NAME_SIZE)), !data.isEmpty {
            return data.withUnsafeBytes { bytes in
                let buffer = bytes.baseAddress!.assumingMemoryBound(to: Int8.self)
                return String(cString: buffer)
            }.trimmingCharacters(in: .controlCharacters)
        }
        return ""
    }

    // MARK: - Packing (tar)

    func packFilesAndDirectories(atPath sourcePath: String) throws {
        setupProgress()
        try innerPackFilesAndDirectories(atPath: sourcePath)
    }

    func packFilesAndDirectories(atPath sourcePath: String, completion: @escaping (Error?) -> Void) {
        setupProgress()
        DispatchQueue.global().async {
            do {
                try self.innerPackFilesAndDirectories(atPath: sourcePath)
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }

    private func innerPackFilesAndDirectories(atPath sourcePath: String) throws {
        let fileManager = FileManager.default
        fileSize = fileManager.fileSizeOfDirectory(atPath: sourcePath)
        updateProgressVirtualTotalUnitCountWithFileSize()

        fileManager.createFile(atPath: filePath, contents: nil)

        guard let fileHandle = FileHandle(forWritingAtPath: filePath) else {
            throw NSError(domain: TAR_ERROR_DOMAIN, code: TAR_ERROR_CODE_BAD_BLOCK)
        }
        defer { try? fileHandle.close() }

        completedVirtualUnitCount = 0

        try pack(sourcePath: sourcePath, to: fileHandle, relativePath: "")

        // Two zero blocks to mark end of archive
        let zeroBlock = Data(count: Int(TAR_BLOCK_SIZE))
        try fileHandle.write(contentsOf: zeroBlock)
        try fileHandle.write(contentsOf: zeroBlock)

        updateProgressVirtualCompletedUnitCountWithTotal()
    }

    private func pack(sourcePath: String, to fileHandle: FileHandle, relativePath: String) throws {
        let fileManager = FileManager.default
        let attributes = try fileManager.attributesOfItem(atPath: sourcePath)
        let isDirectory = attributes[.type] as? FileAttributeType == .typeDirectory

        let size = isDirectory ? 0 : fileManager.fileSizeOfItem(atPath: sourcePath)

        let header = headerFor(path: relativePath, size: size, isDirectory: isDirectory)
        try fileHandle.write(contentsOf: header)

        if !isDirectory {
            guard let sourceHandle = FileHandle(forReadingAtPath: sourcePath) else {
                throw NSError(domain: TAR_ERROR_DOMAIN, code: TAR_ERROR_CODE_BAD_BLOCK)
            }
            defer { try? sourceHandle.close() }

            let maxChunk = TAR_MAX_BLOCK_LOAD_IN_MEMORY * TAR_BLOCK_SIZE

            while true {
                if let data = try? sourceHandle.read(upToCount: Int(maxChunk)), !data.isEmpty {
                    try fileHandle.write(contentsOf: data)

                    completedVirtualUnitCount += Int64(data.count)
                    updateProgressVirtualCompletedUnitCount(completedVirtualUnitCount)
                } else {
                    break
                }
            }

            // Pad to next 512-byte boundary
            let blockSize = UInt64(TAR_BLOCK_SIZE)
            let remainder = size % blockSize
            let paddingSize = remainder == 0 ? 0 : Int(blockSize - remainder)

            if paddingSize > 0 {
                let padding = Data(count: paddingSize)
                try fileHandle.write(contentsOf: padding)
            }
        } else {
            let contents = (try? fileManager.contentsOfDirectory(atPath: sourcePath)) ?? []
            for item in contents.sorted() {
                let fullPath = sourcePath.appendingPathComponent(item)
                let newRelative = relativePath.isEmpty ? item : "\(relativePath)/\(item)"
                try pack(sourcePath: fullPath, to: fileHandle, relativePath: newRelative)
            }
        }
    }

    private func headerFor(path: String, size: UInt64, isDirectory: Bool) -> Data {
        var header = Data(repeating: 0, count: Int(TAR_BLOCK_SIZE))

        header.withUnsafeMutableBytes { rawBuffer in
            guard let base = rawBuffer.baseAddress?.assumingMemoryBound(to: Int8.self) else { return }

            // Name
            if let nameBytes = path.cString(using: .utf8) {
                let copyCount = min(nameBytes.count - 1, USTAR_name_size)
                memcpy(base + USTAR_name_offset, nameBytes, copyCount)
            }

            // Mode
            let modeStr = isDirectory ? "0000755\0" : "0000644\0"
            if let modeBytes = modeStr.cString(using: .utf8) {
                memcpy(base + USTAR_mode_offset, modeBytes, modeBytes.count - 1)
            }

            // UID / GID
            let zero7 = "0000000\0".cString(using: .utf8)!
            memcpy(base + USTAR_uid_offset, zero7, zero7.count - 1)
            memcpy(base + USTAR_gid_offset, zero7, zero7.count - 1)

            // Size
            let sizeStr = String(format: "%011o\0", size)
            if let sizeBytes = sizeStr.cString(using: .utf8) {
                memcpy(base + USTAR_size_offset, sizeBytes, sizeBytes.count - 1)
            }

            // mtime
            let mtime = String(format: "%011o\0", Int(Date().timeIntervalSince1970))
            if let mtimeBytes = mtime.cString(using: .utf8) {
                memcpy(base + USTAR_mtime_offset, mtimeBytes, mtimeBytes.count - 1)
            }

            // Type flag
            base[USTAR_typeflag_offset] = isDirectory ? Int8("5".utf8.first!) : Int8("0".utf8.first!)

            // Magic
            let magic = "ustar\0".cString(using: .utf8)!
            memcpy(base + USTAR_magic_offset, magic, magic.count - 1)

            // Version
            memcpy(base + USTAR_version_offset, "00".cString(using: .utf8)!, 2)

            // Owner / group
            let user = "root\0".cString(using: .utf8)!
            memcpy(base + USTAR_uname_offset, user, min(user.count - 1, USTAR_uname_size))
            memcpy(base + USTAR_gname_offset, user, min(user.count - 1, USTAR_gname_size))

            // Checksum placeholder
            memset(base + USTAR_checksum_offset, Int32(" ".utf8.first!), USTAR_checksum_size)

            // Calculate checksum
            var checksum: UInt32 = 0
            for i in 0..<TAR_BLOCK_SIZE {
                checksum += UInt32(UInt8(bitPattern: base[Int(i)]))
            }

            let checksumStr = String(format: "%06o ", checksum) + "\0"
            if let chkBytes = checksumStr.cString(using: .utf8) {
                memcpy(base + USTAR_checksum_offset, chkBytes, min(chkBytes.count - 1, USTAR_checksum_size))
            }
        }

        return header
    }
}
