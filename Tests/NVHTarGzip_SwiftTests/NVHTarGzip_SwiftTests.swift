//
//  NVHTarGzip_SwiftTests.swift
//  NVHTarGzip-Swift
//
//  Created by roxx990 on 07/01/2026.
//  Copyright © 2026 roxx990. All rights reserved.
//
//  A pure-Swift reimplementation of NVHTarGzip, supporting .tar, .gz, and .tar.gz archives
//  with progress tracking on Apple platforms.
//

import XCTest
@testable import NVHTarGzip_Swift

final class NVHTarGzip_SwiftTests: XCTestCase {

    var tempDir: URL!
    var tgz: NVHTarGzip { NVHTarGzip.shared }

    override func setUpWithError() throws {
        super.setUp()
        // Create a unique temporary directory for each test
        let uuid = UUID().uuidString
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("NVHTarGzipTests_\(uuid)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        // Clean up temp directory after each test
        if let tempDir = tempDir {
            try FileManager.default.removeItem(at: tempDir)
        }
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func createTestFiles() throws {
        let file1URL = tempDir.appendingPathComponent("file1.txt")
        let file2URL = tempDir.appendingPathComponent("file2.txt")
        let subdirURL = tempDir.appendingPathComponent("subdir")
        try FileManager.default.createDirectory(at: subdirURL, withIntermediateDirectories: true)

        try "Hello World".write(to: file1URL, atomically: true, encoding: .utf8)
        try "Second file content".write(to: file2URL, atomically: true, encoding: .utf8)

        let nestedFile = subdirURL.appendingPathComponent("nested.txt")
        try "Nested file".write(to: nestedFile, atomically: true, encoding: .utf8)
    }

    // MARK: - Tests

    func testTarAndUntar() throws {
        try createTestFiles()

        let tarPath = tempDir.appendingPathComponent("archive.tar").path
        let extractPath = tempDir.appendingPathComponent("extracted").path

        // Create tar
        try tgz.tarFile(atPath: tempDir.path, toPath: tarPath)

        XCTAssertTrue(FileManager.default.fileExists(atPath: tarPath))

        // Extract tar
        try tgz.unTarFile(atPath: tarPath, toPath: extractPath)

        let extractedFile1 = URL(fileURLWithPath: extractPath).appendingPathComponent("file1.txt")
        let extractedFile2 = URL(fileURLWithPath: extractPath).appendingPathComponent("file2.txt")
        let extractedNested = URL(fileURLWithPath: extractPath)
            .appendingPathComponent("subdir")
            .appendingPathComponent("nested.txt")

        XCTAssertTrue(FileManager.default.fileExists(atPath: extractedFile1.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: extractedFile2.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: extractedNested.path))

        let content1 = try String(contentsOf: extractedFile1, encoding: .utf8)
        XCTAssertEqual(content1, "Hello World")
    }

    func testGzipAndUnGzip() throws {
        let originalText = "This is a test file for gzip compression."
        let originalFile = tempDir.appendingPathComponent("original.txt")
        try originalText.write(to: originalFile, atomically: true, encoding: .utf8)

        let gzPath = tempDir.appendingPathComponent("compressed.gz").path
        let decompressedPath = tempDir.appendingPathComponent("decompressed.txt").path

        // Compress
        try tgz.gzipFile(atPath: originalFile.path, toPath: gzPath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: gzPath))

        // Decompress
        try tgz.unGzipFile(atPath: gzPath, toPath: decompressedPath)

        let decompressedText = try String(contentsOf: URL(fileURLWithPath: decompressedPath), encoding: .utf8)
        XCTAssertEqual(decompressedText, originalText)
    }

    func testFullTarGzipAndUnTarGzip() throws {
        try createTestFiles()

        let tgzPath = tempDir.appendingPathComponent("archive.tar.gz").path
        let extractPath = tempDir.appendingPathComponent("final_extracted").path

        // Create .tar.gz
        try tgz.tarGzipFile(atPath: tempDir.path, toPath: tgzPath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tgzPath))

        // Extract .tar.gz
        try tgz.unTarGzipFile(atPath: tgzPath, toPath: extractPath)

        let checkFile = URL(fileURLWithPath: extractPath)
            .appendingPathComponent("file1.txt")

        XCTAssertTrue(FileManager.default.fileExists(atPath: checkFile.path))

        let content = try String(contentsOf: checkFile, encoding: .utf8)
        XCTAssertEqual(content, "Hello World")
    }

    // Optional: Test async versions (uncomment if you want)
    /*
    func testAsyncTarGzip() throws {
        try createTestFiles()

        let tgzPath = tempDir.appendingPathComponent("async_archive.tar.gz").path
        let expectation = self.expectation(description: "Async tar+gzip completes")

        tgz.tarGzipFile(atPath: tempDir.path, toPath: tgzPath) { error in
            XCTAssertNil(error)
            XCTAssertTrue(FileManager.default.fileExists(atPath: tgzPath))
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10)
    }
    */
}
