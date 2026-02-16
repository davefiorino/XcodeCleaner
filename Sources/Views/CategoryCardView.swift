// Created by Davide Fiorino

import SwiftUI

struct CategoryCardView: View {
    let category: CategoryType
    let size: Int64
    let items: [CategoryItem]
    let deletionProgress: DeletionProgress
    let onRescan: () -> Void

    @State private var isExpanded = false
    @State private var selectedItems: Set<UUID> = []
    @State private var showDeleteAlert = false
    @State private var showInfo = false

    private var hasContent: Bool { size > 0 }
    private var hasSelection: Bool { !selectedItems.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: category.systemImage)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)

                Text(category.rawValue)
                    .font(.system(size: 14, weight: .semibold))

                if category.infoText != nil {
                    Button {
                        showInfo.toggle()
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showInfo, arrowEdge: .bottom) {
                        Text(category.infoText ?? "")
                            .font(.system(size: 12))
                            .padding(12)
                            .frame(width: 240)
                    }
                }

                Spacer()

                Text(FormatUtils.formatBytes(size))
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(size > 1_000_000_000 ? .orange : .secondary)

                if category != .coreSimulator {
                    Button {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                            .foregroundStyle(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .disabled(!hasContent)
                    .help(hasSelection ? "Move selected to Trash" : "Move all to Trash")
                }
            }

            if category == .coreSimulator {
                Text("Delete from Xcode")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            // Expandable items list
            if !items.isEmpty {
                DisclosureGroup(isExpanded: $isExpanded) {
                    itemsList
                } label: {
                    Text(items.count == 1 ? "1 Item" : "\(items.count) Items")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .font(.system(size: 12))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
        )
        .alert(
            hasSelection
                ? "Move \(selectedItems.count) selected item\(selectedItems.count == 1 ? "" : "s") to Trash?"
                : "Move all \(category.rawValue) to Trash?",
            isPresented: $showDeleteAlert
        ) {
            Button("Move to Trash", role: .destructive) {
                if hasSelection {
                    deleteSelected()
                } else {
                    deleteAll()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if hasSelection {
                Text("The selected items will be moved to Trash.")
            } else {
                Text("All items in \(category.rawValue) will be moved to Trash.")
            }
        }
    }

    private var allSelected: Bool {
        !items.isEmpty && items.allSatisfy { selectedItems.contains($0.id) }
    }

    private var isReadOnly: Bool { category == .coreSimulator }

    @ViewBuilder
    private var itemsList: some View {
        VStack(spacing: 2) {
            if !isReadOnly {
                HStack(spacing: 8) {
                    Toggle(isOn: Binding(
                        get: { allSelected },
                        set: { isOn in
                            if isOn {
                                selectedItems = Set(items.map(\.id))
                            } else {
                                selectedItems.removeAll()
                            }
                        }
                    )) {
                        EmptyView()
                    }
                    .toggleStyle(.checkbox)
                    .controlSize(.small)

                    Text("Select All")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding(.vertical, 2)

                Divider()
            }

            ForEach(items) { item in
                HStack(spacing: 8) {
                    if !isReadOnly {
                        Toggle(isOn: Binding(
                            get: { selectedItems.contains(item.id) },
                            set: { isOn in
                                if isOn {
                                    selectedItems.insert(item.id)
                                } else {
                                    selectedItems.remove(item.id)
                                }
                            }
                        )) {
                            EmptyView()
                        }
                        .toggleStyle(.checkbox)
                        .controlSize(.small)
                    }

                    Text(cleanName(item.name))
                        .font(.system(size: 11))
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Text(FormatUtils.formatBytes(item.size))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }

            if !isReadOnly && !selectedItems.isEmpty {
                HStack {
                    Spacer()
                    Text("\(selectedItems.count) selected")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
            }
        }
        .padding(.top, 4)
    }

    private func cleanName(_ name: String) -> String {
        // Clean up derived data folder names by removing hash suffixes
        if category == .derivedData {
            if let dashRange = name.range(of: "-", options: .backwards) {
                let prefix = String(name[name.startIndex..<dashRange.lowerBound])
                if prefix.count > 2 { return prefix }
            }
        }
        return name
    }

    private func deleteSelected() {
        let toDelete = items.filter { selectedItems.contains($0.id) }
        Task {
            do {
                _ = try await CleanerService.moveToTrash(toDelete, category: category, progress: deletionProgress)
                selectedItems.removeAll()
                onRescan()
            } catch {}
        }
    }

    private func deleteAll() {
        Task {
            do {
                _ = try await CleanerService.moveAllToTrash(category, progress: deletionProgress)
                selectedItems.removeAll()
                onRescan()
            } catch {}
        }
    }
}
