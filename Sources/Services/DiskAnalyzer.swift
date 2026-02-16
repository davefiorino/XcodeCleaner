// Created by Davide Fiorino

import Foundation

let simulatorSafeAppDataSubdirs = [
    "data/Containers/Data/Application",
    "data/Containers/Bundle/Application"
]

@MainActor
final class DiskAnalyzer: ObservableObject {
    @Published var storageInfo = StorageInfo(totalSpace: 0, usedSpace: 0, freeSpace: 0)
    @Published var categorySizes: [CategoryType: Int64] = [:]
    @Published var categoryItems: [CategoryType: [CategoryItem]] = [:]
    @Published var isScanning = false
    @Published var trashSize: Int64 = 0

    func scanAll() {
        rescan(CategoryType.allCases)
    }

    func rescan(_ categories: some Collection<CategoryType>) {
        isScanning = true
        storageInfo = StorageInfo.current()
        let toScan = Array(categories)

        Task.detached {
            var sizes: [CategoryType: Int64] = [:]
            var items: [CategoryType: [CategoryItem]] = [:]

            for category in toScan {
                let (size, categoryItemsList) = Self.scanCategory(category)
                sizes[category] = size
                items[category] = categoryItemsList
            }

            let trash = Self.scanTrashSize()

            await MainActor.run { [sizes, items, trash] in
                for (cat, size) in sizes {
                    self.categorySizes[cat] = size
                }
                for (cat, itemList) in items {
                    self.categoryItems[cat] = itemList
                }
                self.trashSize = trash
                self.isScanning = false
            }
        }
    }

    private nonisolated static func scanTrashSize() -> Int64 {
        let fm = FileManager.default
        let trashPath = fm.homeDirectoryForCurrentUser
            .appendingPathComponent(".Trash").path
        guard fm.fileExists(atPath: trashPath) else { return 0 }
        return directorySize(atPath: trashPath, fm: fm)
    }

    private nonisolated static func scanCategory(_ category: CategoryType) -> (Int64, [CategoryItem]) {
        if category == .simulatorAppData {
            return scanSimulatorAppData()
        }

        let basePath = category.basePath
        let fm = FileManager.default
        guard fm.fileExists(atPath: basePath) else {
            return (0, [])
        }

        var totalSize: Int64 = 0
        var items: [CategoryItem] = []

        do {
            let contents = try fm.contentsOfDirectory(atPath: basePath)
            for item in contents {
                if item.hasPrefix(".") { continue }
                let fullPath = (basePath as NSString).appendingPathComponent(item)
                let size = directorySize(atPath: fullPath, fm: fm)
                totalSize += size
                items.append(CategoryItem(name: item, path: fullPath, size: size))
            }
        } catch {}

        items.sort { $0.size > $1.size }
        return (totalSize, items)
    }

    private nonisolated static func scanSimulatorAppData() -> (Int64, [CategoryItem]) {
        let fm = FileManager.default
        let basePath = CategoryType.simulatorAppData.basePath
        guard fm.fileExists(atPath: basePath) else { return (0, []) }

        var totalSize: Int64 = 0
        var items: [CategoryItem] = []

        guard let deviceUUIDs = try? fm.contentsOfDirectory(atPath: basePath) else {
            return (0, [])
        }

        for uuid in deviceUUIDs {
            if uuid.hasPrefix(".") { continue }
            let devicePath = (basePath as NSString).appendingPathComponent(uuid)

            var deviceSize: Int64 = 0
            var appDataPaths: [String] = []
            for subdir in simulatorSafeAppDataSubdirs {
                let path = (devicePath as NSString).appendingPathComponent(subdir)
                guard fm.fileExists(atPath: path) else { continue }
                let size = directorySize(atPath: path, fm: fm)
                deviceSize += size
                appDataPaths.append(path)
            }

            guard deviceSize > 0 else { continue }

            let deviceName = simulatorDeviceName(atPath: devicePath, fm: fm) ?? uuid
            // Store the device path; deletion will target only safe subdirs
            items.append(CategoryItem(name: deviceName, path: devicePath, size: deviceSize))
            totalSize += deviceSize
        }

        items.sort { $0.size > $1.size }
        return (totalSize, items)
    }

    private nonisolated static func simulatorDeviceName(atPath devicePath: String, fm: FileManager) -> String? {
        let plistPath = (devicePath as NSString).appendingPathComponent("device.plist")
        guard let data = fm.contents(atPath: plistPath),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let name = plist["name"] as? String else {
            return nil
        }
        let runtime = (plist["runtime"] as? String)?
            .replacingOccurrences(of: "com.apple.CoreSimulator.SimRuntime.", with: "")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "OS ", with: "OS ") ?? ""
        return runtime.isEmpty ? name : "\(name) (\(runtime))"
    }

    private nonisolated static func directorySize(atPath path: String, fm: FileManager) -> Int64 {
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
