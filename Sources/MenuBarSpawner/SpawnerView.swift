import SwiftUI

struct SpawnerView: View {
    @Environment(SpawnerManager.self) private var manager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            ItemsView()
                .environment(manager)
                .padding(12)
            Divider()
            footer
        }
        .frame(width: 320)
    }

    private var header: some View {
        HStack {
            Image(systemName: "menubar.rectangle").foregroundStyle(.tint)
            Text("Menu Bar Spawner").font(.headline)
            Spacer()
        }
        .padding(12)
    }

    private var footer: some View {
        HStack {
            Text("\(manager.items.count) item(s) active")
                .font(.caption2).foregroundStyle(.secondary)
            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .font(.caption2).foregroundStyle(.secondary).buttonStyle(.plain)
        }
        .padding(12)
    }
}
