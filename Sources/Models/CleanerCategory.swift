// Created by Davide Fiorino

import Foundation

enum CategoryType: String, CaseIterable, Identifiable {
    case derivedData = "Derived Data"
    case archives = "Archives"
    case deviceSupport = "Device Support"
    case coreSimulator = "Simulators"
    case simulatorAppData = "Simulator App Data"
    case spmCache = "SPM Cache"
    case cocoapodsCache = "CocoaPods Cache"
    case logs = "Xcode Logs"

    var id: String { rawValue }

    var basePath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        switch self {
        case .derivedData:
            return "\(home)/Library/Developer/Xcode/DerivedData"
        case .archives:
            return "\(home)/Library/Developer/Xcode/Archives"
        case .deviceSupport:
            return "\(home)/Library/Developer/Xcode/iOS DeviceSupport"
        case .coreSimulator:
            return "\(home)/Library/Developer/CoreSimulator/Devices"
        case .simulatorAppData:
            return "\(home)/Library/Developer/CoreSimulator/Devices"
        case .spmCache:
            return "\(home)/Library/Caches/org.swift.swiftpm"
        case .cocoapodsCache:
            return "\(home)/Library/Caches/CocoaPods"
        case .logs:
            return "\(home)/Library/Developer/Xcode/UserData/Logs"
        }
    }

    var systemImage: String {
        switch self {
        case .derivedData: return "hammer"
        case .archives: return "archivebox"
        case .deviceSupport: return "iphone"
        case .coreSimulator: return "ipad.and.iphone"
        case .simulatorAppData: return "app.badge"
        case .spmCache: return "shippingbox"
        case .cocoapodsCache: return "puzzlepiece"
        case .logs: return "doc.plaintext"
        }
    }
    var infoText: String? {
        switch self {
        case .deviceSupport:
            return "Debug symbol files for physical devices. Xcode downloads these when you connect a device. Safe to delete — Xcode will re-download them when needed."
        case .coreSimulator:
            return "Full simulator devices. Deleting removes the simulator entirely (uses simctl delete). Xcode recreates default devices on next launch."
        default:
            return nil
        }
    }
}

struct CategoryItem: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    var size: Int64
    var isSelected: Bool = false
}
