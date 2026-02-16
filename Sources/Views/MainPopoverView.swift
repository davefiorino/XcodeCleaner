// Created by Davide Fiorino

import SwiftUI

struct MainPopoverView: View {
    @StateObject private var analyzer = DiskAnalyzer()

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                StorageBarView(storageInfo: analyzer.storageInfo)

                ForEach(CategoryType.allCases) { category in
                    CategoryCardView(
                        category: category,
                        size: analyzer.categorySizes[category] ?? 0,
                        items: analyzer.categoryItems[category] ?? [],
                        onDeleteAll: {},
                        onRescan: { analyzer.scanAll() }
                    )
                }

                RefreshFooterView(
                    isScanning: analyzer.isScanning,
                    onRefresh: { analyzer.scanAll() }
                )
            }
            .padding(16)
        }
        .frame(width: 420, height: 620)
        .background(Color(nsColor: .windowBackgroundColor))
        .task {
            analyzer.scanAll()
        }
    }
}

struct RefreshFooterView: View {
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
