// Created by Davide Fiorino

import SwiftUI

struct StorageBarView: View {
    let storageInfo: StorageInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mac Storage")
                .font(.system(size: 15, weight: .semibold))

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * storageInfo.usageRatio)
                }
            }
            .frame(height: 10)

            Text("\(FormatUtils.formatBytes(storageInfo.usedSpace)) of \(FormatUtils.formatBytes(storageInfo.totalSpace)) used")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
        )
    }
}
