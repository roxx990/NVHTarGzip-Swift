//
//  NVHProgress.swift
//  NVHTarGzip-Swift
//
//  Created by roxx990 on 07/01/2026.
//  Copyright © 2026 roxx990. All rights reserved.
//
//  A pure-Swift reimplementation of NVHTarGzip, supporting .tar, .gz, and .tar.gz archives
//  with progress tracking on Apple platforms.
//


import Foundation

let NVHProgressMaxTotalUnitCount: Int64 = 100

class NVHProgress {
    private var progress: Progress
    private var countFraction: Double = 0.0

    init() {
        progress = Progress(totalUnitCount: NVHProgressMaxTotalUnitCount)
        progress.isCancellable = false
        progress.isPausable = false
    }

    func setVirtualTotalUnitCount(_ virtualTotalUnitCount: Int64) {
        countFraction = Double(NVHProgressMaxTotalUnitCount) / Double(virtualTotalUnitCount)
    }

    func setVirtualCompletedUnitCount(_ virtualUnitCount: Int64) {
        progress.completedUnitCount = Int64(round(countFraction * Double(virtualUnitCount)))
    }

    func setVirtualCompletedUnitCountToTotal() {
        progress.completedUnitCount = NVHProgressMaxTotalUnitCount
    }
}
