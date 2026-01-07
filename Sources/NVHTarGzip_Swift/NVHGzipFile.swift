//
//  NVHGzipFile.swift
//  NVHTarGzip-Swift
//
//  Created by roxx990 on 07/01/2026.
//  Copyright © 2026 roxx990. All rights reserved.
//
//  A pure-Swift reimplementation of NVHTarGzip, supporting .tar, .gz, and .tar.gz archives
//  with progress tracking on Apple platforms.
//


import Foundation
import zlib

let NVHGzipFileZlibErrorDomain = "io.nvh.targzip.zlib.error"

enum NVHGzipFileErrorType: Int {
    case none = 0
    case decompressionFailed = -1
    case unexpectedZlibState = -2
    case sourceOrDestinationFilePathIsNil = -3
    case compressionFailed = -4
    case unknown = -999
}

public class NVHGzipFile: NVHFile {

    func inflate(toPath destinationPath: String) throws {
        setupProgress()
        try innerInflate(toPath: destinationPath)
    }

    func inflate(toPath destinationPath: String, completion: @escaping (Error?) -> Void) {
        setupProgress()
        DispatchQueue.global().async {
            do {
                try self.innerInflate(toPath: destinationPath)
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch let error {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }

    private func innerInflate(toPath destinationPath: String) throws {
        updateProgressVirtualTotalUnitCountWithFileSize()

        guard !filePath.isEmpty, !destinationPath.isEmpty else {
            throw NSError(domain: NVHGzipFileZlibErrorDomain, code: NVHGzipFileErrorType.sourceOrDestinationFilePathIsNil.rawValue)
        }

        FileManager.default.createFile(atPath: destinationPath, contents: nil)

        let result = inflateGzip(sourcePath: filePath, destination: destinationPath)

        if result != .none {
            throw NSError(domain: NVHGzipFileZlibErrorDomain, code: result.rawValue)
        }
    }

    private func inflateGzip(sourcePath: String, destination: String) -> NVHGzipFileErrorType {
        guard let outputStream = OutputStream(toFileAtPath: destination, append: false) else {
            return .decompressionFailed
        }
        outputStream.open()
        defer { outputStream.close() }

        guard let sourceCString = sourcePath.cString(using: .ascii) else {
            return .unknown
        }

        let mode = "rb".cString(using: .utf8)!

        let sourceGzFile = gzopen(sourceCString, UnsafePointer(mode))

        let bufferLength = 1024 * 256
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: bufferLength, alignment: 8)
        defer { buffer.deallocate() }

        var errorType: NVHGzipFileErrorType = .none

        while true {
            let readBytes = gzread(sourceGzFile, buffer, UInt32(bufferLength))

            let dataOffset = gzoffset(sourceGzFile)
            updateProgressVirtualCompletedUnitCount(Int64(dataOffset))

            if readBytes > 0 {
                let data = Data(bytes: buffer, count: Int(readBytes))
                let writtenBytes = outputStream.write(data.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! }, maxLength: Int(readBytes))
                if writtenBytes <= 0 {
                    errorType = .decompressionFailed
                    break
                }
            } else if readBytes == 0 {
                break
            } else {
                errorType = readBytes == -1 ? .decompressionFailed : .unexpectedZlibState
                break
            }
        }

        updateProgressVirtualCompletedUnitCountWithTotal()
        _ = gzclose(sourceGzFile)
        return errorType
    }

    func deflate(fromPath sourcePath: String) throws {
        setupProgress()
        try innerDeflate(fromPath: sourcePath)
    }

    func deflate(fromPath sourcePath: String, completion: @escaping (Error?) -> Void) {
        setupProgress()
        DispatchQueue.global().async {
            do {
                try self.innerDeflate(fromPath: sourcePath)
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch let error {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }

    private func innerDeflate(fromPath sourcePath: String) throws {
        updateProgressVirtualTotalUnitCount(Int64(FileManager.default.fileSizeOfItem(atPath: sourcePath)))

        guard !filePath.isEmpty, !sourcePath.isEmpty else {
            throw NSError(domain: NVHGzipFileZlibErrorDomain, code: NVHGzipFileErrorType.sourceOrDestinationFilePathIsNil.rawValue)
        }

        let result = deflateToGzip(destinationPath: filePath, source: sourcePath)

        if result != .none {
            throw NSError(domain: NVHGzipFileZlibErrorDomain, code: result.rawValue)
        }
    }

    private func deflateToGzip(destinationPath: String, source: String) -> NVHGzipFileErrorType {
        guard let inputStream = InputStream(fileAtPath: source) else {
            return .compressionFailed
        }
        inputStream.open()
        defer { inputStream.close() }

        guard let destinationCString = destinationPath.cString(using: .ascii) else {
            return .unknown
        }

        let mode = "wb".cString(using: .utf8)!

        let destinationGzFile = gzopen(destinationCString, UnsafePointer(mode))

        let bufferLength = 1024 * 256
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: bufferLength, alignment: 8)
        defer { buffer.deallocate() }

        var totalReadBytes: Int64 = 0
        var errorType: NVHGzipFileErrorType = .none

        while true {
            let readBytes = inputStream.read(buffer.assumingMemoryBound(to: UInt8.self), maxLength: bufferLength)
            totalReadBytes += Int64(readBytes)
            updateProgressVirtualCompletedUnitCount(totalReadBytes)

            if readBytes > 0 {
                let writtenBytes = gzwrite(destinationGzFile, buffer, UInt32(readBytes))
                if writtenBytes <= 0 {
                    errorType = .compressionFailed
                    break
                }
            } else if readBytes == 0 {
                break
            } else {
                errorType = readBytes == -1 ? .compressionFailed : .unexpectedZlibState
                break
            }
        }

        updateProgressVirtualCompletedUnitCountWithTotal()

        let gzError = gzclose(destinationGzFile)
        if gzError != Z_OK {
            errorType = .unexpectedZlibState
        }

        return errorType
    }
}
