import SwiftUI

private let presetIcons: [(label: String, symbol: String)] = [
    ("Circle",  "circle.fill"),    ("Star",    "star.fill"),
    ("Bell",    "bell.fill"),      ("Bolt",    "bolt.fill"),
    ("Flag",    "flag.fill"),      ("Heart",   "heart.fill"),
    ("Cloud",   "cloud.fill"),     ("Flame",   "flame.fill"),
    ("Gear",    "gearshape.fill"), ("Tag",     "tag.fill"),
    ("Lock",    "lock.fill"),      ("Key",     "key.fill"),
    ("Eye",     "eye.fill"),       ("Wifi",    "wifi"),
    ("Battery", "battery.100"),   ("Chart",   "chart.bar.fill"),
]

struct ItemsView: View {
    @Environment(SpawnerManager.self) private var manager

    @State private var newTitle     = ""
    @State private var selectedIcon = "circle.fill"
    @State private var customIcon   = ""
    @State private var useCustom    = false

    private var resolvedIcon: String { useCustom ? customIcon : selectedIcon }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            spawnForm
            Divider()
            activeList
        }
    }

    // MARK: – Spawn form

    private var spawnForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("New Item", systemImage: "plus.app")
                .font(.caption.bold()).foregroundStyle(.secondary)

            HStack {
                Text("Label").font(.caption).foregroundStyle(.secondary).frame(width: 38, alignment: .leading)
                TextField("optional text", text: $newTitle).textFieldStyle(.roundedBorder).font(.caption)
            }

            Text("Icon").font(.caption).foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(30), spacing: 4), count: 8), spacing: 4) {
                ForEach(presetIcons, id: \.symbol) { item in
                    Button {
                        selectedIcon = item.symbol
                        useCustom    = false
                        customIcon   = ""
                    } label: {
                        Image(systemName: item.symbol)
                            .font(.system(size: 13))
                            .frame(width: 26, height: 26)
                            .background(
                                selectedIcon == item.symbol && !useCustom
                                    ? Color.accentColor.opacity(0.2) : Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                    .help(item.label)
                }
            }

            HStack {
                Toggle("Custom SF Symbol", isOn: $useCustom)
                    .font(.caption).toggleStyle(.checkbox)
                if useCustom {
                    TextField("e.g. airpodspro", text: $customIcon)
                        .textFieldStyle(.roundedBorder).font(.caption)
                }
            }

            HStack(spacing: 10) {
                // Preview
                HStack(spacing: 4) {
                    if !resolvedIcon.isEmpty,
                       NSImage(systemSymbolName: resolvedIcon, accessibilityDescription: nil) != nil {
                        Image(systemName: resolvedIcon).font(.system(size: 11))
                    }
                    if !newTitle.isEmpty { Text(newTitle).font(.system(size: 11)) }
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color(NSColor.windowBackgroundColor))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.secondary.opacity(0.3)))

                Spacer()

                Button {
                    manager.spawn(title: newTitle, icon: resolvedIcon)
                } label: {
                    Label("Spawn", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent).controlSize(.small)
                .disabled(resolvedIcon.isEmpty && newTitle.isEmpty)
            }
        }
    }

    // MARK: – Active list

    private var activeList: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Active (\(manager.items.count))", systemImage: "menubar.rectangle")
                    .font(.caption.bold()).foregroundStyle(.secondary)
                Spacer()
                if !manager.items.isEmpty {
                    Button("Remove All") { manager.removeAll() }
                        .font(.caption2).foregroundStyle(.red).buttonStyle(.plain)
                }
            }

            if manager.items.isEmpty {
                Text("No items spawned yet.")
                    .font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 4) {
                    ForEach(manager.items) { item in
                        HStack(spacing: 8) {
                            Group {
                                if !item.icon.isEmpty,
                                   NSImage(systemSymbolName: item.icon, accessibilityDescription: nil) != nil {
                                    Image(systemName: item.icon)
                                } else {
                                    Image(systemName: "square.dashed").foregroundStyle(.secondary)
                                }
                            }
                            .font(.system(size: 12)).frame(width: 16)

                            Text(item.title.isEmpty ? "(no label)" : item.title)
                                .font(.caption)
                                .foregroundStyle(item.title.isEmpty ? .secondary : .primary)

                            Spacer()

                            Text(item.created, style: .relative)
                                .font(.caption2).foregroundStyle(.secondary)

                            Button { manager.remove(id: item.id) } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 8).padding(.vertical, 5)
                        .background(Color(NSColor.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
    }
}
