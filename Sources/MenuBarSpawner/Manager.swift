import AppKit
import Observation

struct SpawnedItem: Identifiable {
    let id      = UUID()
    let title   : String
    let icon    : String
    let nsItem  : NSStatusItem
    let created = Date()
}

@MainActor
@Observable
final class SpawnerManager: NSObject {
    private(set) var items: [SpawnedItem] = []

    // MARK: - Public

    func spawn(title: String, icon: String) {
        let nsItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        configure(nsItem, title: title, icon: icon)

        let spawned = SpawnedItem(title: title, icon: icon, nsItem: nsItem)

        let menu    = NSMenu()
        let header  = NSMenuItem(title: title.isEmpty ? "(item)" : title,
                                 action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        let remove  = NSMenuItem(title: "Remove",
                                 action: #selector(handleRemove(_:)),
                                 keyEquivalent: "")
        remove.target            = self
        remove.representedObject = spawned.id.uuidString
        menu.addItem(remove)

        nsItem.menu = menu
        items.append(spawned)
    }

    func remove(id: UUID) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        NSStatusBar.system.removeStatusItem(items[i].nsItem)
        items.remove(at: i)
    }

    func removeAll() {
        items.forEach { NSStatusBar.system.removeStatusItem($0.nsItem) }
        items.removeAll()
    }

    // MARK: - Private

    private func configure(_ nsItem: NSStatusItem, title: String, icon: String) {
        guard let btn = nsItem.button else { return }
        let symbol = icon.isEmpty ? "circle.fill" : icon
        btn.image        = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
        btn.imageScaling = .scaleProportionallyDown
        if title.isEmpty {
            btn.imagePosition = .imageOnly
        } else {
            btn.title         = " \(title)"
            btn.imagePosition = .imageLeft
        }
    }

    // AppKit always calls menu target-action on the main thread — matches @MainActor.
    @objc private func handleRemove(_ sender: NSMenuItem) {
        guard
            let raw = sender.representedObject as? String,
            let id  = UUID(uuidString: raw)
        else { return }
        remove(id: id)
    }
}
