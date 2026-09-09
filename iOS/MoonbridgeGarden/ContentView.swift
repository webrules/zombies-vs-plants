import SwiftUI

struct ContentView: View {
    @ObservedObject var game: GameModel
    @State private var showingGuide = false
    @State private var audioStatus = ""

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 500
            ZStack {
                LinearGradient(colors: [Color(red: 0.93, green: 0.81, blue: 0.73),
                                        Color(red: 0.58, green: 0.78, blue: 0.65)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                VStack(spacing: compact ? 4 : 10) {
                    header(compact: compact)
                    HStack(spacing: compact ? 6 : 12) {
                        seedTray(compact: compact)
                            .frame(width: compact ? 116 : 156)
                        VStack(spacing: 4) {
                            statusBar
                            if let hazard = game.terrainHazard {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text("\(hazard.kind.title) • Rows \(hazard.lanes.sorted().map { String($0 + 1) }.joined(separator: ", ")) • \(Int(ceil(hazard.remaining)))s")
                                }
                                .font(.system(size: compact ? 10 : 13, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10).padding(.vertical, 3)
                                .frame(maxWidth: .infinity)
                                .background(hazard.kind == .shadow ? Color.purple : hazard.kind == .frost ? Color.blue : Color.teal, in: Capsule())
                                .accessibilityIdentifier("hazardBanner")
                            }
                            GardenBoard(game: game)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.7), lineWidth: 2))
                            Text(game.selectedPlant == .cornCannon && !game.cornPlacementMode
                                 ? "Tap a garden cell to aim • Tap the Corn card to place another"
                                 : "\(game.selectedPlant.rawValue) • Tap an empty ring, or slide to aim and release")
                                .font(.system(size: compact ? 10 : 13, weight: .semibold))
                                .foregroundStyle(.brown)
                                .lineLimit(1).minimumScaleFactor(0.7)
                        }
                    }
                }
                .padding(compact ? 6 : 14)
                if game.phase != .playing { startOrEndOverlay(compact: compact) }
            }
        }
        .sheet(isPresented: $showingGuide) { guide }
    }

    private func header(compact: Bool) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 0) {
                Text("MOONBRIDGE GARDEN")
                    .font(.system(size: compact ? 17 : 25, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.42, green: 0.10, blue: 0.14))
                if !compact {
                    Text("Ten defenders. Five terraces. One garden to protect.")
                        .font(.caption).foregroundStyle(.brown)
                }
            }
            .lineLimit(1).minimumScaleFactor(0.65)
            Spacer(minLength: 0)
            Button {
                game.pauseGame()
                showingGuide = true
            } label: { Image(systemName: "questionmark.circle") .frame(width: 44, height: 44) }
                .accessibilityLabel("How to play")
            Button { game.soundEnabled.toggle() } label: {
                Image(systemName: game.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(game.soundEnabled ? "Mute sound" : "Enable sound")
            .accessibilityIdentifier("soundButton")
            if game.phase == .playing {
                Button(game.isPaused ? "Resume" : "Pause") { game.togglePause() }
                    .font(.subheadline.bold())
                    .frame(minWidth: 64, minHeight: 44)
                    .accessibilityIdentifier("pauseButton")
            }
        }
        .tint(.brown)
        .frame(height: compact ? 44 : 54)
    }

    private var statusBar: some View {
        HStack(spacing: 8) {
            Text("WAVE \(game.wave)/3").fontWeight(.black)
            Text(game.selectedDifficulty.rawValue.uppercased()).foregroundStyle(.yellow)
            ProgressView(value: game.waveProgress).tint(.yellow).frame(maxWidth: 150)
            Spacer(minLength: 0)
            Text("\(game.zombies.count) SAMURAI")
            if game.zombies.contains(where: { $0.kind.isBoss }) {
                Text("BOSS").foregroundStyle(.yellow).fontWeight(.black)
            }
        }
        .font(.system(size: 11, weight: .semibold)).monospacedDigit()
        .foregroundStyle(.white)
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Color(red: 0.15, green: 0.24, blue: 0.22), in: Capsule())
        .accessibilityElement(children: .combine)
    }

    private func seedTray(compact: Bool) -> some View {
        VStack(spacing: 4) {
            Label(game.sunshine.formatted(), systemImage: "sun.max.fill")
                .font(.system(size: compact ? 18 : 23, weight: .black)).monospacedDigit()
                .foregroundStyle(.yellow).padding(.vertical, 6)
                .accessibilityIdentifier("sunshine")
                .accessibilityLabel("Sunshine")
                .accessibilityValue(String(game.sunshine))
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(PlantKind.allCases) { kind in
                        Button { game.selectPlant(kind) } label: {
                            seedCard(kind, compact: compact)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("seed-\(kind.symbol)")
                        .accessibilityLabel("\(kind.rawValue), \(kind.cost) sunshine")
                        .accessibilityValue(game.selectedPlant == kind ? "Selected" : "")
                    }
                }.padding(3)
            }
            .scrollIndicators(.visible)
            Text("SCROLL FOR SEEDS ↓")
                .font(.system(size: 8, weight: .bold)).foregroundStyle(.white.opacity(0.85))
        }
        .padding(5)
        .background(LinearGradient(colors: [Color(red: 0.48, green: 0.08, blue: 0.13),
                                           Color(red: 0.24, green: 0.07, blue: 0.10)],
                                   startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 14))
    }

    private func seedCard(_ kind: PlantKind, compact: Bool) -> some View {
        let remaining = cooldown(for: kind)
        let selected = game.selectedPlant == kind
        return VStack(spacing: 2) {
            HStack(spacing: 4) {
                Text(kind.symbol).font(.system(size: 9, weight: .black))
                Spacer(minLength: 0)
                Text("☀ \(kind.cost)").font(.system(size: 10, weight: .bold))
            }
            Text(kind.rawValue)
                .font(.system(size: compact ? 11 : 14, weight: .bold)).lineLimit(1).minimumScaleFactor(0.7)
            if remaining > 0 {
                Text("\(Int(ceil(remaining)))s recharge")
                    .font(.system(size: 9, weight: .semibold)).foregroundStyle(.red)
            }
        }
        .foregroundStyle(.brown)
        .frame(maxWidth: .infinity, minHeight: compact ? 44 : 60)
        .padding(.horizontal, 5).padding(.vertical, 3)
        .background(selected ? .white : Color(red: 0.98, green: 0.91, blue: 0.75), in: RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(selected ? .yellow : .clear, lineWidth: 3))
        .opacity(game.sunshine < kind.cost ? 0.55 : 1)
    }

    private func cooldown(for kind: PlantKind) -> Double {
        switch kind {
        case .cherryBomb: game.cherryCooldown
        case .redHotPepper: game.pepperCooldown
        case .cornCannon: game.cornCooldown
        case .charmMushroom: game.charmCooldown
        default: 0 // Ice Pea and Gatling timers do not block placement in the source game.
        }
    }

    private func startOrEndOverlay(compact: Bool) -> some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            ScrollView {
                VStack(spacing: compact ? 10 : 18) {
                    Text(game.phase == .ready ? "DEFEND MOONBRIDGE" : game.phase == .won ? "GARDEN SAVED!" : "THE GARDEN WAS OVERRUN")
                        .font(.system(size: compact ? 25 : 38, weight: .black, design: .rounded))
                        .foregroundStyle(.yellow)
                        .multilineTextAlignment(.center)
                    Text(game.phase == .ready ? "\(game.selectedDifficulty.startingSunshine.formatted()) sunshine • 10 plants • 3 waves" : game.phase == .won ? "Your plants held every terrace." : "A samurai crossed the left garden boundary.")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("difficultySummary")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(Difficulty.allCases) { difficulty in
                            Button { game.selectedDifficulty = difficulty } label: {
                                HStack {
                                    Text(difficulty.rawValue)
                                    Spacer()
                                    if game.selectedDifficulty == difficulty { Image(systemName: "checkmark.circle.fill") }
                                }
                                .font(.subheadline.bold()).foregroundStyle(.white)
                                .padding(.horizontal, 12).frame(minHeight: 44)
                                .background(game.selectedDifficulty == difficulty ? .red.opacity(0.7) : .white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                            }
                            .accessibilityIdentifier("difficulty-\(difficulty.rawValue)")
                        }
                    }
                    Text(game.selectedDifficulty.subtitle).font(.caption).foregroundStyle(.white.opacity(0.85))
                    Button(game.phase == .ready ? "Start Level" : "Play Again") { game.start() }
                        .buttonStyle(.borderedProminent).tint(.orange)
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("startButton")
                }
                .padding(compact ? 16 : 28)
                .frame(maxWidth: 540)
                .background(Color(red: 0.25, green: 0.14, blue: 0.15), in: RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(.yellow.opacity(0.6), lineWidth: 2))
                .padding(12)
                .frame(maxWidth: .infinity)
            }
            .defaultScrollAnchor(.center)
        }
    }

    private var guide: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Sound").font(.headline)
                    Button("Test Sound") {
                        game.soundEnabled = true
                        AudioSynth.shared.play(.win)
                        audioStatus = AudioSynth.shared.diagnosticSummary
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("testSoundButton")
                    Text(audioStatus.isEmpty ? "Sound On plays even in Silent Mode. Use the iPad volume buttons to adjust media volume; check Bluetooth or AirPlay if sound is routed elsewhere." : audioStatus)
                        .font(.callout)
                        .accessibilityIdentifier("audioStatus")
                    Text("Protect five garden terraces").font(.title2.bold())
                    Text("Play in landscape. Scroll the seed tray, choose a plant, then tap an empty planting ring. You can also slide your finger across the garden to preview a cell, then lift to plant. Lift over the surrounding scenery to cancel.")
                    Text("Sunflowers generate sunshine. Walls hold enemies while pea shooters attack. Ice peas slow enemies; Flame Stakes turn passing peas into fire or steam-flame shots. Gatling shooters fire five-pea bursts.")
                    Text("Cherry Bombs hit a nearby three-row area. Red Hot Peppers sweep a lane. Place a Corn Cannon and then tap a garden cell to aim; tap its seed card again to place another. Charm Mushrooms turn an enemy into an ally for up to eight seconds, except the immune Thunder Shogun.")
                    Text("Watch the boss warnings").font(.headline)
                    Text("On Easy, the Hammer Shogun takes three direct cherry bombs and the Ice Doctor takes five. Harder modes increase enemy health, so bosses need more hits. Ice orbs damage and slow the first plant in their lane. Flame Giants burn plants; the Thunder Shogun marks a plant before lightning destroys it. Other attacks also reduce boss health.")
                    Text("Difficulty and shifting terrain").font(.headline)
                    Text("Easy starts with 1,500 sunshine, Normal with 1,200, Hard with 1,000, and Hell with 800. Harder paths reduce sunflower income and slow/charm duration, increase enemy speed and health, and extend powerful-plant recharges. Hell sends two complete invasions; Hard and Hell can coordinate boss attacks.")
                    Text("At wave transitions, colored, striped terraces mark temporary hazards. The banner names affected rows and shows time remaining. Frost and shadow slow plant actions and reduce sunshine; terrain also changes enemy speed. Above Easy, a strong defense can trigger a small, bounded speed increase at the next wave.")
                    Text("Pause stops the action. Opening this guide, leaving the app, or receiving an audio interruption pauses the game; tap Resume when ready. The in-game speaker button mutes music and effects. Games restart when the app is terminated.")
                }.padding()
            }
            .navigationTitle("Garden Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showingGuide = false } } }
        }
    }
}

private struct GardenBoard: View {
    @ObservedObject var game: GameModel
    @State private var previewCell: GridCell?

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                LawnRenderer.draw(context: &context, size: size, game: game, hoveredCell: previewCell)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard !game.isPaused else { return }
                    previewCell = GardenProjection(size: proxy.size).cell(at: value.location)
                }
                .onEnded { value in
                    defer { previewCell = nil }
                    guard !game.isPaused,
                          let cell = GardenProjection(size: proxy.size).cell(at: value.location) else { return }
                    game.plant(at: cell)
                })
            .accessibilityIdentifier("gardenBoard")
            .accessibilityLabel("Five terrace garden")
            .accessibilityChildren {
                ForEach(0..<5, id: \.self) { row in
                    ForEach(0..<9, id: \.self) { column in
                        let cell = GridCell(row: row, column: column)
                        Button {
                            if !game.isPaused { game.plant(at: cell) }
                        } label: {
                            Text("Row \(row + 1), column \(column + 1), \(game.plants[cell]?.kind.rawValue ?? "empty")")
                        }
                    }
                }
            }
        }
    }
}
