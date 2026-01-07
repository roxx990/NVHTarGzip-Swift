//
//  NVHProgress.swift
//  Quran Chat
//
//  Created by Macbook Pro on 07/01/2026.
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
