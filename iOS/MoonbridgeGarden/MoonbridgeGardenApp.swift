import AVFoundation
import SwiftUI

@main
struct MoonbridgeGardenApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var session = MobileGameSession()

    var body: some Scene {
        WindowGroup {
            ContentView(game: session.game)
                .preferredColorScheme(.light)
                .onAppear { session.setForeground(scenePhase == .active) }
                .onChange(of: scenePhase) { _, phase in
                    session.setForeground(phase == .active)
                }
                .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { note in
                    guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                          let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
                    session.setInterrupted(type == .began)
                }
                .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.mediaServicesWereResetNotification)) { _ in
                    AudioSynth.shared.recoverAfterMediaServicesReset()
                }
        }
    }
}

/// Returning from Home, Control Center, or a call requires an explicit Resume.
@MainActor
final class MobileGameSession: ObservableObject {
    let game = GameModel()
    private var foreground = false
    private var interrupted = false

    func setForeground(_ value: Bool) {
        foreground = value
        updateActivity()
    }

    func setInterrupted(_ value: Bool) {
        interrupted = value
        updateActivity()
    }

    private func updateActivity() {
        let active = foreground && !interrupted
        if !active { game.pauseGame() }
        AudioSynth.shared.setActive(active)
    }
}
