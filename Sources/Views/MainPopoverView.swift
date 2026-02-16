// Created by Davide Fiorino

import SwiftUI

struct MainPopoverView: View {
    @StateObject private var analyzer = DiskAnalyzer()
    @StateObject private var deletionProgress = DeletionProgress()

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 12) {
                    StorageBarView(storageInfo: analyzer.storageInfo)

                    RefreshBarView(
                        isScanning: analyzer.isScanning,
                        onRefresh: { analyzer.scanAll() }
                    )

                    ForEach(CategoryType.allCases) { category in
                        CategoryCardView(
                            category: category,
                            size: analyzer.categorySizes[category] ?? 0,
                            items: analyzer.categoryItems[category] ?? [],
                            deletionProgress: deletionProgress,
                            onRescan: { analyzer.rescan([category]) }
                        )
                        .disabled(deletionProgress.isActive)
                    }

                    TrashCardView(size: analyzer.trashSize)
                }
                .padding(16)
            }

            if deletionProgress.isActive {
                DeletionProgressOverlay(progress: deletionProgress)
            }
        }
        .frame(width: 420, height: 620)
        .background(Color(nsColor: .windowBackgroundColor))
        .task {
            analyzer.scanAll()
        }
    }
}

struct DeletionProgressOverlay: View {
    @ObservedObject var progress: DeletionProgress

    var body: some View {
        VStack(spacing: 12) {
            ProgressView(value: progress.fractionCompleted) {
                Text("Moving to Trash...")
                    .font(.system(size: 13, weight: .medium))
            }
            .progressViewStyle(.linear)
            .tint(.blue)

            Text(progress.statusText)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThickMaterial)
                .shadow(radius: 8)
        )
        .padding(.horizontal, 40)
    }
}

struct RefreshBarView: View {
    let isScanning: Bool
    let onRefresh: () -> Void

    var body: some View {
        HStack {
            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .disabled(isScanning)

            if isScanning {
                ProgressView()
                    .controlSize(.small)
                    .padding(.leading, 4)
                Text("Scanning...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.top, 4)
    }
}
