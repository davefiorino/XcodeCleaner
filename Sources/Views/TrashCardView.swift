// Created by Davide Fiorino

import SwiftUI

struct TrashCardView: View {
    let size: Int64

    var body: some View {
        HStack {
            Image(systemName: "trash")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Text("Trash")
                .font(.system(size: 14, weight: .semibold))

            Spacer()

            Text(FormatUtils.formatBytes(size))
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
        )
    }
}
