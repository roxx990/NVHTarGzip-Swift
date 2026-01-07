//
//  NVHFile.swift
//  NVHTarGzip-Swift
//
//  Created by roxx990 on 07/01/2026.
//  Copyright © 2026 roxx990. All rights reserved.
//
//  A pure-Swift reimplementation of NVHTarGzip, supporting .tar, .gz, and .tar.gz archives
//  with progress tracking on Apple platforms.
//


import Foundation

class NVHFile {
    let filePath: String
    var fileSize: UInt64

    private var progress: NVHProgress?

    init(path: String) {
        filePath = path
        fileSize = FileManager.default.fileSizeOfItem(atPath: path)
    }

    func setupProgress() {
        progress = NVHProgress()
    }

    func updateProgressVirtualTotalUnitCount(_ virtualUnitCount: Int64) {
        progress?.setVirtualTotalUnitCount(virtualUnitCount)
    }

    func updateProgressVirtualCompletedUnitCount(_ virtualUnitCount: Int64) {
        progress?.setVirtualCompletedUnitCount(virtualUnitCount)
    }

    func updateProgressVirtualTotalUnitCountWithFileSize() {
        updateProgressVirtualTotalUnitCount(Int64(fileSize))
    }

    func updateProgressVirtualCompletedUnitCountWithTotal() {
        progress?.setVirtualCompletedUnitCountToTotal()
    }
}
