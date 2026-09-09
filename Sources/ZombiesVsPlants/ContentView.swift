import SwiftUI

struct ContentView: View {
    @StateObject private var game = GameModel()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.90, green: 0.73, blue: 0.78), Color(red: 0.96, green: 0.90, blue: 0.72), Color(red: 0.54, green: 0.77, blue: 0.69)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 12) {
                header
                HStack(alignment: .top, spacing: 14) {
                    plantTray
                    VStack(spacing: 10) {
                        statusBar
                        if game.selectedPlant == .cornCannon {
                            Text(game.cornPlacementMode ? "Place a cannon; then click a grid to aim. Click card to place another." : "CORN TARGETING: click any lawn grid to fire.")
                                .font(.caption.weight(.black))
                                .foregroundStyle(game.cornPlacementMode ? .brown : .red)
                                .padding(.horizontal, 12).padding(.vertical, 5)
                                .background(.white.opacity(0.72), in: Capsule())
                        }
                        if game.selectedPlant == .icePeaShooter {
                            Text("ICE PEA: blue shots damage and slow every enemy, including bosses.")
                                .font(.caption.weight(.black))
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 12).padding(.vertical, 5)
                                .background(.white.opacity(0.72), in: Capsule())
                        }
                        if game.selectedPlant == .flameStake {
                            Text("FLAME STAKE: peas passing through gain fire; Ice Peas become steam-flame shots.")
                                .font(.caption.weight(.black))
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 12).padding(.vertical, 5)
                                .background(.white.opacity(0.72), in: Capsule())
                        }
                        if game.selectedPlant == .gatlingPeaShooter {
                            Text("GATLING: five rapid peas per burst; high cost, 8-second cooldown.")
                                .font(.caption.weight(.black))
                                .foregroundStyle(.green)
                                .padding(.horizontal, 12).padding(.vertical, 5)
                                .background(.white.opacity(0.72), in: Capsule())
                        }
                        GameBoard(game: game)
                            .aspectRatio(9.0 / 5.0, contentMode: .fit)
                            .background(.black.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.7), lineWidth: 3))
                            .shadow(color: .black.opacity(0.22), radius: 10, y: 5)
                        Text("Choose a seed packet, then click an empty lawn square to plant.")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.brown.opacity(0.85))
                    }
                }
            }
            .padding(20)

            if game.phase != .playing {
                endOverlay
            }
        }
        .preferredColorScheme(.light)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: -2) {
                HStack(spacing: 8) {
                    Circle().fill(.red).frame(width: 15,height:15)
                    Text("ZOMBIES vs PLANTS")
                        .foregroundStyle(Color(red: 0.30, green: 0.12, blue: 0.15))
                }
                Text("MOONBRIDGE GARDEN")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(Color(red:0.48,green:0.11,blue:0.14))
            }
            .font(.system(size: 28, weight: .black, design: .rounded))
            .rotationEffect(.degrees(-2))
            Spacer()
            Button {
                game.soundEnabled.toggle()
            } label: {
                Label(game.soundEnabled ? "Sound On" : "Sound Off", systemImage: game.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
            }
            .buttonStyle(.bordered)
            if game.phase == .playing {
                Button(game.isPaused ? "Resume" : "Pause") { game.togglePause() }
                    .buttonStyle(.borderedProminent)
                    .tint(.brown)
                    .keyboardShortcut("p", modifiers: [])
                    .help("Pause or resume the game (P)")
            }
        }
    }

    private var plantTray: some View {
        VStack(spacing: 10) {
            Label("\(game.sunshine)", systemImage: "sun.max.fill")
                .font(.title2.bold())
                .foregroundStyle(.orange)
                .padding(.vertical, 8)
            ScrollView(.vertical) {
                LazyVStack(spacing: 10) {
                    ForEach(PlantKind.allCases) { kind in
                        Button { game.selectPlant(kind) } label: {
                            PlantCard(kind: kind, selected: game.selectedPlant == kind,
                                      affordable: game.sunshine >= kind.cost,
                                      cooldown: kind == .cherryBomb ? game.cherryCooldown : kind == .redHotPepper ? game.pepperCooldown : kind == .cornCannon ? game.cornCooldown : kind == .charmMushroom ? game.charmCooldown : kind == .icePeaShooter ? game.icePeaCooldown : kind == .gatlingPeaShooter ? game.gatlingCooldown : 0,
                                      cooldownDuration: cooldownDuration(for: kind),
                                      animationTime: game.elapsed)
                        }
                        .buttonStyle(.plain)
                        .disabled(game.phase != .playing)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.visible)
            .frame(minHeight: 500, maxHeight: .infinity)
            Spacer(minLength: 0)
            Text("GARDEN NOTE\n\(game.selectedDifficulty.rawValue): \(game.selectedDifficulty.startingSunshine) sun.\nHazards shift each wave.")
                .font(.caption.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.92))
                .padding(8)
                .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(10)
        .frame(width: 150)
        .frame(minHeight: 620, maxHeight: .infinity)
        .background(LinearGradient(colors:[Color(red:0.48,green:0.07,blue:0.10),Color(red:0.24,green:0.07,blue:0.10)],startPoint:.top,endPoint:.bottom), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.yellow.opacity(0.55), lineWidth: 2))
    }

    private func cooldownDuration(for kind: PlantKind) -> Double {
        let baseDuration: Double = switch kind {
        case .redHotPepper: GameModel.pepperCooldownDuration
        case .cornCannon: GameModel.cornCannonCooldownDuration
        case .charmMushroom: GameModel.charmMushroomCooldownDuration
        case .icePeaShooter: GameModel.icePeaCooldownDuration
        case .gatlingPeaShooter: GameModel.gatlingCooldownDuration
        default: GameModel.cherryCooldownDuration
        }
        let scalesWithDifficulty = kind == .cherryBomb || kind == .redHotPepper ||
            kind == .cornCannon || kind == .charmMushroom
        return scalesWithDifficulty ? baseDuration * game.selectedDifficulty.cooldownMultiplier : baseDuration
    }

    private var statusBar: some View {
        HStack(spacing: 12) {
            Text("WAVE \(game.wave) / 3")
                .font(.headline.monospacedDigit())
                .foregroundStyle(.white)
            ProgressView(value: game.waveProgress)
                .tint(.yellow)
            Text(game.selectedDifficulty.rawValue.uppercased())
                .font(.caption.weight(.black))
                .foregroundStyle(.yellow)
            if let hazard = game.terrainHazard {
                Text("\(hazard.kind.title) \(Int(ceil(hazard.remaining)))s")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(hazard.kind == .frost ? .cyan : hazard.kind == .shadow ? .purple : .teal, in: Capsule())
            }
            Text("\(game.zombies.count) ON LAWN")
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(.white.opacity(0.9))
            if game.zombies.contains(where: { $0.kind == .hammerGiant }) {
                Text("SHOGUN")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.yellow)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(.red, in: Capsule())
            }
            if game.zombies.contains(where: { $0.kind == .iceDoctor }) {
                Text("ICE DOCTOR")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(.blue, in: Capsule())
            }
            if game.zombies.contains(where: { $0.kind == .flameGiant }) {
                Text("FLAME GIANT")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(.orange, in: Capsule())
            }
            if game.zombies.contains(where: { $0.kind == .thunderShogun }) {
                Text("FINAL BOSS")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(.purple, in: Capsule())
            }
            if game.zombies.contains(where: { $0.kind == .dancerSamurai }) {
                Text("DANCER")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(.orange, in: Capsule())
            }
            if let tanuki = game.tanukiEvent {
                Text("TANUKI TRICK \(Int(ceil(tanuki.remaining)))s")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(.yellow, in: Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(Color(red: 0.16, green: 0.17, blue: 0.25), in: Capsule())
    }

    @ViewBuilder private var endOverlay: some View {
        Color.black.opacity(0.55).ignoresSafeArea()
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let pulse = 1 + sin(time * 2.8) * 0.025
            ZStack {
                if game.phase == .won {
                    ForEach(0..<16, id: \.self) { i in
                        Circle()
                            .fill(i.isMultiple(of: 2) ? .yellow : .orange)
                            .frame(width: 8, height: 8)
                            .offset(x: cos(time * 0.8 + Double(i)) * CGFloat(150 + i * 7),
                                    y: sin(time * 1.1 + Double(i) * 0.8) * CGFloat(100 + i * 4))
                            .opacity(0.7)
                    }
                }
                VStack(spacing: 18) {
                    Text(game.phase == .won ? "YOU WIN!" : game.phase == .lost ? "ZOMBIES ATE\nYOUR BRAINS" : "DEFEND THE LAWN!")
                        .font(.system(size: game.phase == .lost ? 40 : 50, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(game.phase == .won ? .yellow : game.phase == .lost ? .green : .white)
                        .shadow(color: game.phase == .lost ? .red.opacity(0.5) : .black, radius: game.phase == .lost ? 9 : 2, y: 3)
                        .scaleEffect(pulse)
                    Text(game.phase == .ready ? "Defend the moonbridge garden through three waves. The final wave brings four mighty bosses." : game.phase == .won ? "The garden is peaceful again. All four mighty bosses have fallen." : "A samurai invader crossed the moonbridge gate.")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    if game.phase == .ready {
                        VStack(spacing: 10) {
                            Text("CHOOSE YOUR PATH")
                                .font(.caption.weight(.black))
                                .tracking(2)
                                .foregroundStyle(.yellow)
                            Text("Garden Difficulty")
                                .font(.title2.weight(.black))
                                .foregroundStyle(.white)
                            Text("Starting sunshine is limited; hazards and enemy pressure scale by path.")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white.opacity(0.75))
                            ForEach(Difficulty.allCases) { difficulty in
                                Button {
                                    game.selectedDifficulty = difficulty
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: difficulty == .hard ? "flame.fill" : difficulty == .normal ? "leaf.fill" : "sparkles")
                                            .font(.title3)
                                            .frame(width: 28)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(difficulty.rawValue)
                                                .font(.headline.weight(.bold))
                                            Text(difficulty.subtitle)
                                                .font(.caption)
                                                .foregroundStyle(.white.opacity(0.78))
                                        }
                                        Spacer()
                                        if game.selectedDifficulty == difficulty {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.yellow)
                                        }
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 11)
                                    .frame(maxWidth: 430, alignment: .leading)
                                    .background(game.selectedDifficulty == difficulty ? Color.red.opacity(0.72) : Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 14))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(game.selectedDifficulty == difficulty ? .yellow.opacity(0.9) : .white.opacity(0.18), lineWidth: game.selectedDifficulty == difficulty ? 2 : 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: 430)
                    }
                    Button(game.phase == .ready ? "Start Level" : "Play Again") { game.start() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(game.phase == .lost ? .green : .orange)
                        .keyboardShortcut(.defaultAction)
                }
                .padding(38)
                .background(.brown.opacity(0.9), in: RoundedRectangle(cornerRadius: 26))
                .overlay(RoundedRectangle(cornerRadius: 26).stroke(.white.opacity(0.8), lineWidth: 3))
                .shadow(radius: 20)
            }
        }
    }
}

private struct PlantCard: View {
    let kind: PlantKind
    let selected: Bool
    let affordable: Bool
    let cooldown: Double
    let cooldownDuration: Double
    let animationTime: Double

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Circle().fill(cardColor.opacity(0.9)).frame(width: 45, height: 45)
                Text(kind.symbol).font(.system(size: 9, weight: .black, design: .rounded)).foregroundStyle(.white)
                if cooldown > 0 {
                    Circle()
                        .trim(from: 0, to: 1 - cooldown / cooldownDuration)
                        .stroke(.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 49, height: 49)
                        .rotationEffect(.degrees(-90))
                }
            }
            Text(kind.rawValue).font(.caption.bold()).lineLimit(1).minimumScaleFactor(0.75)
            Label("\(kind.cost)", systemImage: "sun.max.fill").font(.caption2.bold()).foregroundStyle(.orange)
            if cooldown > 0 {
                Text("\(Int(ceil(cooldown)))s").font(.caption2.bold()).foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(selected ? Color.white : Color.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? Color.orange : .brown.opacity(0.25), lineWidth: selected ? 3 : 1))
        .scaleEffect(selected ? 1.025 + sin(animationTime * 5) * 0.01 : 1)
        .opacity(affordable && cooldown <= 0 ? 1 : 0.52)
    }

    private var cardColor: Color {
        switch kind {
        case .sunflower: .yellow
        case .peaShooter: .green
        case .wallPlant: .brown
        case .cherryBomb: .red
        case .redHotPepper: Color(red: 0.84, green: 0.12, blue: 0.08)
        case .cornCannon: Color(red: 0.83, green: 0.60, blue: 0.08)
        case .charmMushroom: Color(red: 0.55, green: 0.20, blue: 0.68)
        case .icePeaShooter: Color(red: 0.18, green: 0.62, blue: 0.92)
        case .flameStake: Color(red: 0.84, green: 0.28, blue: 0.08)
        case .gatlingPeaShooter: Color(red: 0.18, green: 0.48, blue: 0.20)
        }
    }
}

private struct GameBoard: View {
    @ObservedObject var game: GameModel
    @State private var hoveredCell: GridCell?

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                LawnRenderer.draw(context: &context, size: size, game: game, hoveredCell: hoveredCell)
            }
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                switch phase {
                case .active(let location): hoveredCell = GardenProjection(size: proxy.size).cell(at: location)
                case .ended: hoveredCell = nil
                }
            }
            .gesture(SpatialTapGesture().onEnded { value in
                if let cell = GardenProjection(size: proxy.size).cell(at: value.location) {
                    game.plant(at: cell)
                }
            })
            .offset(x: sin(game.elapsed * 75) * game.screenShake * 9,
                    y: cos(game.elapsed * 61) * game.screenShake * 5)
            .accessibilityLabel("Five row lawn game board")
            .accessibilityHint("Click a planting ring on a grass terrace. Water and scenery are not planting areas.")
        }
    }

}
