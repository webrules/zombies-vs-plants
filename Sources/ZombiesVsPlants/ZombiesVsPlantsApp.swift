import SwiftUI

@main
struct ZombiesVsPlantsApp: App {
    var body: some Scene {
        WindowGroup("Zombies vs Plants") {
            ContentView()
                .frame(minWidth: 980, minHeight: 680)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1180, height: 780)
    }
}
