//
//  NVHTarGzip.swift
//  NVHTarGzip-Swift
//
//  Created by roxx990 on 07/01/2026.
//  Copyright © 2026 roxx990. All rights reserved.
//
//  A pure-Swift reimplementation of NVHTarGzip, supporting .tar, .gz, and .tar.gz archives
//  with progress tracking on Apple platforms.
//


import Foundation

public class NVHTarGzip {
    public static let shared = NVHTarGzip()

    private init() {}

    // Synchronous API
    public func unTarFile(atPath sourcePath: String, toPath destinationPath: String) throws {
        let tarFile = NVHTarFile(path: sourcePath)
        try tarFile.createFilesAndDirectories(atPath: destinationPath)
    }

    public func unGzipFile(atPath sourcePath: String, toPath destinationPath: String) throws {
        let gzipFile = NVHGzipFile(path: sourcePath)
        try gzipFile.inflate(toPath: destinationPath)
    }

    public func unTarGzipFile(atPath sourcePath: String, toPath destinationPath: String) throws {
        let temporaryPath = temporaryFilePath(for: sourcePath)
        try unGzipFile(atPath: sourcePath, toPath: temporaryPath)
        try unTarFile(atPath: temporaryPath, toPath: destinationPath)
        try FileManager.default.removeItem(atPath: temporaryPath)
    }

    public func tarFile(atPath sourcePath: String, toPath destinationPath: String) throws {
        let tarFile = NVHTarFile(path: destinationPath)
        try tarFile.packFilesAndDirectories(atPath: sourcePath)
    }

    public func gzipFile(atPath sourcePath: String, toPath destinationPath: String) throws {
        let gzipFile = NVHGzipFile(path: destinationPath)
        try gzipFile.deflate(fromPath: sourcePath)
    }

    public func tarGzipFile(atPath sourcePath: String, toPath destinationPath: String) throws {
        let temporaryPath = temporaryFilePath(for: sourcePath)
        try tarFile(atPath: sourcePath, toPath: temporaryPath)
        try gzipFile(atPath: temporaryPath, toPath: destinationPath)
        try FileManager.default.removeItem(atPath: temporaryPath)
    }

    // Asynchronous API
    public func unTarFile(atPath sourcePath: String, toPath destinationPath: String, completion: @escaping (Error?) -> Void) {
        let tarFile = NVHTarFile(path: sourcePath)
        tarFile.createFilesAndDirectories(atPath: destinationPath, completion: completion)
    }

    public func unGzipFile(atPath sourcePath: String, toPath destinationPath: String, completion: @escaping (Error?) -> Void) {
        let gzipFile = NVHGzipFile(path: sourcePath)
        gzipFile.inflate(toPath: destinationPath, completion: completion)
    }

    public func unTarGzipFile(atPath sourcePath: String, toPath destinationPath: String, completion: @escaping (Error?) -> Void) {
        let temporaryPath = temporaryFilePath(for: sourcePath)
        unGzipFile(atPath: sourcePath, toPath: temporaryPath) { gzipError in
            if let error = gzipError {
                completion(error)
                return
            }
            self.unTarFile(atPath: temporaryPath, toPath: destinationPath) { tarError in
                try? FileManager.default.removeItem(atPath: temporaryPath)
                completion(tarError)
            }
        }
    }

    public func tarFile(atPath sourcePath: String, toPath destinationPath: String, completion: @escaping (Error?) -> Void) {
        let tarFile = NVHTarFile(path: destinationPath)
        tarFile.packFilesAndDirectories(atPath: sourcePath, completion: completion)
    }

    public func gzipFile(atPath sourcePath: String, toPath destinationPath: String, completion: @escaping (Error?) -> Void) {
        let gzipFile = NVHGzipFile(path: destinationPath)
        gzipFile.deflate(fromPath: sourcePath, completion: completion)
    }

    public func tarGzipFile(atPath sourcePath: String, toPath destinationPath: String, completion: @escaping (Error?) -> Void) {
        let temporaryPath = temporaryFilePath(for: sourcePath)
        tarFile(atPath: sourcePath, toPath: temporaryPath) { tarError in
            if let error = tarError {
                completion(error)
                return
            }
            self.gzipFile(atPath: temporaryPath, toPath: destinationPath) { gzipError in
                try? FileManager.default.removeItem(atPath: temporaryPath)
                completion(gzipError)
            }
        }
    }

    private func temporaryFilePath(for path: String) -> String {
        let uuid = UUID().uuidString
        var filename = path.lastPathComponent.deletingPathExtension
        filename += "-\(uuid)"
        var temporaryPath = NSTemporaryDirectory().appendingPathComponent(filename)
        if temporaryPath.pathExtension != "tar" {
            temporaryPath = temporaryPath.appendingPathExtension("tar")
        }
        return temporaryPath
    }
}
