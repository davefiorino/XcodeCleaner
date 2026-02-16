// Created by Davide Fiorino

import Foundation

@MainActor
final class DeletionProgress: ObservableObject {
    @Published var isActive = false
    @Published var fractionCompleted: Double = 0
    @Published var statusText: String = ""

    func update(fraction: Double, status: String) {
        fractionCompleted = fraction
        statusText = status
    }

    func start() {
        isActive = true
        fractionCompleted = 0
        statusText = "Preparing..."
    }

    func finish() {
        isActive = false
    }
}

enum CleanerService {

    static func moveToTrash(
        _ items: [CategoryItem],
        category: CategoryType? = nil,
        progress: DeletionProgress? = nil
    ) async throws -> Int64 {
        let totalSize = items.reduce(Int64(0)) { $0 + $1.size }
        let showProgress = totalSize > 1_000_000_000 && progress != nil

        if showProgress {
            await progress?.start()
        }

        var freed: Int64 = 0
        for (index, item) in items.enumerated() {
            let cat = category
            let result = try await Task.detached {
                try clearItem(item, category: cat)
            }.value
            freed += result

            if showProgress {
                let fraction = Double(index + 1) / Double(items.count)
                let status = "\(FormatUtils.formatBytes(freed)) / \(FormatUtils.formatBytes(totalSize))"
                await progress?.update(fraction: fraction, status: status)
            }
        }

        if showProgress {
            await progress?.finish()
        }
        return freed
    }

    static func moveAllToTrash(
        _ category: CategoryType,
        progress: DeletionProgress? = nil
    ) async throws -> Int64 {
        let basePath = category.basePath
        let fm = FileManager.default
        guard fm.fileExists(atPath: basePath) else { return 0 }

        let contents = try fm.contentsOfDirectory(atPath: basePath)
            .filter { !$0.hasPrefix(".") }

        let itemsWithSizes: [(path: String, size: Int64)] = contents.map { item in
            let fullPath = (basePath as NSString).appendingPathComponent(item)
            return (fullPath, itemSize(atPath: fullPath, fm: fm))
        }

        let totalSize = itemsWithSizes.reduce(Int64(0)) { $0 + $1.size }
        let showProgress = totalSize > 1_000_000_000 && progress != nil

        if showProgress {
            await progress?.start()
        }

        var freed: Int64 = 0
        for (index, entry) in itemsWithSizes.enumerated() {
            let cat = category
            let result = await Task.detached {
                if cat == .coreSimulator {
                    return deleteSimulatorViaSimctl(devicePath: entry.path, size: entry.size)
                } else {
                    let url = URL(fileURLWithPath: entry.path)
                    try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                    return entry.size
                }
            }.result
            if case .success(let size) = result {
                freed += size
            }

            if showProgress {
                let fraction = Double(index + 1) / Double(itemsWithSizes.count)
                let status = "\(FormatUtils.formatBytes(freed)) / \(FormatUtils.formatBytes(totalSize))"
                await progress?.update(fraction: fraction, status: status)
            }
        }

        if showProgress {
            await progress?.finish()
        }
        return freed
    }

    private static func clearItem(_ item: CategoryItem, category: CategoryType? = nil) throws -> Int64 {
        let fm = FileManager.default
        let plistPath = (item.path as NSString).appendingPathComponent("device.plist")
        let isSimulatorDevice = fm.fileExists(atPath: plistPath)

        if isSimulatorDevice && category == .simulatorAppData {
            return try clearSimulatorAppData(devicePath: item.path, fm: fm)
        }
        if isSimulatorDevice && category == .coreSimulator {
            return deleteSimulatorViaSimctl(devicePath: item.path, size: item.size)
        }
        let url = URL(fileURLWithPath: item.path)
        try fm.trashItem(at: url, resultingItemURL: nil)
        return item.size
    }

    private static func deleteSimulatorViaSimctl(devicePath: String, size: Int64) -> Int64 {
        let udid = (devicePath as NSString).lastPathComponent
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["simctl", "delete", udid]
        try? process.run()
        process.waitUntilExit()
        return process.terminationStatus == 0 ? size : 0
    }

    private static func clearSimulatorAppData(devicePath: String, fm: FileManager) throws -> Int64 {
        var freed: Int64 = 0
        for subdir in simulatorSafeAppDataSubdirs {
            let path = (devicePath as NSString).appendingPathComponent(subdir)
            guard fm.fileExists(atPath: path) else { continue }
            let contents = try fm.contentsOfDirectory(atPath: path)
            for entry in contents {
                let fullPath = (path as NSString).appendingPathComponent(entry)
                let size = itemSize(atPath: fullPath, fm: fm)
                try fm.trashItem(at: URL(fileURLWithPath: fullPath), resultingItemURL: nil)
                freed += size
            }
        }
        return freed
    }

    private static func itemSize(atPath path: String, fm: FileManager) -> Int64 {
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: path, isDirectory: &isDir) else { return 0 }

        if !isDir.boolValue {
            let attrs = try? fm.attributesOfItem(atPath: path)
            return attrs?[.size] as? Int64 ?? 0
        }

        var size: Int64 = 0
        guard let enumerator = fm.enumerator(atPath: path) else { return 0 }

        while let file = enumerator.nextObject() as? String {
            let fullPath = (path as NSString).appendingPathComponent(file)
            let attrs = try? fm.attributesOfItem(atPath: fullPath)
            if let fileSize = attrs?[.size] as? Int64 {
                size += fileSize
            }
        }
        return size
    }
}
