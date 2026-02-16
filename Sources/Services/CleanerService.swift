// Created by Davide Fiorino

import Foundation

enum CleanerService {

    static func deleteCategory(_ category: CategoryType) throws -> Int64 {
        let basePath = category.basePath
        let fm = FileManager.default
        guard fm.fileExists(atPath: basePath) else { return 0 }

        var freedSpace: Int64 = 0
        let contents = try fm.contentsOfDirectory(atPath: basePath)

        for item in contents {
            if item.hasPrefix(".") { continue }
            let fullPath = (basePath as NSString).appendingPathComponent(item)
            let size = Self.itemSize(atPath: fullPath, fm: fm)
            try fm.removeItem(atPath: fullPath)
            freedSpace += size
        }
        return freedSpace
    }

    static func deleteItems(_ items: [CategoryItem]) throws -> Int64 {
        let fm = FileManager.default
        var freed: Int64 = 0
        for item in items {
            guard fm.fileExists(atPath: item.path) else { continue }
            try fm.removeItem(atPath: item.path)
            freed += item.size
        }
        return freed
    }

    static func moveToTrash(_ items: [CategoryItem]) throws -> Int64 {
        var freed: Int64 = 0
        for item in items {
            let url = URL(fileURLWithPath: item.path)
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            freed += item.size
        }
        return freed
    }

    static func moveAllToTrash(_ category: CategoryType) throws -> Int64 {
        let basePath = category.basePath
        let fm = FileManager.default
        guard fm.fileExists(atPath: basePath) else { return 0 }

        var freed: Int64 = 0
        let contents = try fm.contentsOfDirectory(atPath: basePath)

        for item in contents {
            if item.hasPrefix(".") { continue }
            let fullPath = (basePath as NSString).appendingPathComponent(item)
            let size = Self.itemSize(atPath: fullPath, fm: fm)
            let url = URL(fileURLWithPath: fullPath)
            try fm.trashItem(at: url, resultingItemURL: nil)
            freed += size
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
