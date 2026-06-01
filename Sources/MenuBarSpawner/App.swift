import SwiftUI

@main
struct MenuBarSpawnerApp: App {
    @State private var manager = SpawnerManager()

    var body: some Scene {
        MenuBarExtra {
            SpawnerView()
                .environment(manager)
        } label: {
            Image(systemName: "menubar.rectangle")
        }
        .menuBarExtraStyle(.window)
    }
}
