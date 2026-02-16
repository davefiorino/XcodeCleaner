// Created by Davide Fiorino

import Foundation

struct StorageInfo {
    let totalSpace: Int64
    let usedSpace: Int64
    let freeSpace: Int64

    var usageRatio: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(usedSpace) / Double(totalSpace)
    }

    static func current() -> StorageInfo {
        let fileURL = URL(fileURLWithPath: "/")
        do {
            let values = try fileURL.resourceValues(forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey
            ])
            let total = Int64(values.volumeTotalCapacity ?? 0)
            let available = values.volumeAvailableCapacityForImportantUsage ?? 0
            let used = total - Int64(available)
            return StorageInfo(totalSpace: total, usedSpace: used, freeSpace: Int64(available))
        } catch {
            return StorageInfo(totalSpace: 0, usedSpace: 0, freeSpace: 0)
        }
    }
}
