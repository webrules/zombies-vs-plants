# Moonbridge Garden for iOS

A standalone native SwiftUI port, synchronized with the September 6, 2026 macOS artwork and difficulty update. Open `MoonbridgeGarden.xcodeproj` in this folder. The project contains its own source and tests; it does not reference the parent macOS package and can be moved or copied independently.

## Run

Requires Xcode 16 or newer and iOS/iPadOS 17 or newer. The game supports iPhone and iPad in both landscape orientations, with full-screen play on iPad.

1. Open `MoonbridgeGarden.xcodeproj` in Xcode.
2. Select the **MoonbridgeGarden** scheme and an iPhone or iPad simulator.
3. Press **Run** (⌘R). Choose a difficulty and tap **Start Level**.
4. To run on a physical device, check the development team under the app target’s **Signing & Capabilities**, choose a unique bundle identifier if needed, and select the connected device. This local project retains the signing team used for the connected iPad deployment.

From this folder, a simulator build needs no developer account:

```sh
xcodebuild -project MoonbridgeGarden.xcodeproj -scheme MoonbridgeGarden \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath DerivedData build CODE_SIGNING_ALLOWED=NO
```

## Touch controls

- Scroll the seed tray to reach all ten plants. Each card shows its sunshine cost, selection, and any placement recharge.
- Tap an empty garden ring to plant. For more precise placement on a small screen, touch and slide to preview a cell, then lift to plant. Lift over scenery to cancel. The projected garden coordinates are used for both drawing and touch input.
- Place a Corn Cannon, then tap a garden cell to target its missile. Tap the Corn card again to place another cannon.
- Use **Pause / Resume**, the speaker button, and the question-mark guide in the top bar. Opening the guide pauses the game.
- Leaving the foreground or receiving an audio interruption pauses the simulation. Returning does not automatically resume combat. Audio stops in the background and can mix with other apps. **Sound On now plays even in iPad Silent Mode**; the in-game speaker button mutes both music and effects.
- Open the question-mark guide and tap **Test Sound** to enable sound, hear a short cue, and see the active output route and media volume. Use the iPad volume buttons if media volume is zero, and check Bluetooth/AirPlay routing if necessary.
- VoiceOver exposes named seed controls and all 45 garden cells. Board placement is disabled while paused.

The app keeps the active run in memory; terminating it starts a new game. This port does not add saved games, networking, advertising, or in-app purchases.

## Preserved gameplay

There are five terraces, three waves, ten plants, original procedural Japanese-garden scenery, samurai and dancer opponents, the Tanuki event, and win/lose states. The latest Mac difficulty rules are now included:

| Difficulty | Starting sunshine | Enemy speed / health | Invasion |
| --- | ---: | --- | --- |
| Easy | 1,500 | Base | Base schedule |
| Normal | 1,200 | +12% / +8% | Extra cross-lane enemies |
| Hard | 1,000 | +28% / +16% | Denser waves; coordinated bosses |
| Hell | 800 | +55% / +28% | Exactly twice the base schedule, including bosses; coordinated bosses |

Harder modes also reduce sunflower income and slow/charm duration, extend powerful-plant recharge times, and shorten boss attack cooldowns. Hell allows ten dancers per wave (thirty total); the other modes allow five per wave. A stable defense above Easy can trigger up to two bounded adaptive-pressure steps, each adding 3.5% to the enemy speed multiplier.

Wave transitions activate temporary lane hazards. Frost and shadow tint and stripe affected terraces, slow plant actions, modify enemy speed, and reduce sunflower income. The wet-moss hazard is also supported by the model. A mobile banner shows the hazard name, affected rows, and seconds remaining. Hazards last 4.5 / 7 / 9 / 11 seconds on Easy / Normal / Hard / Hell.

All seven enemy types now use the latest articulated samurai renderer: jointed walking limbs, planted attack stances, weathered armor, layered helmets, cloth folds, distinct weapons, readable boss charge poses, and mirrored charmed allies. Status and health overlays remain upright.

The plants are Sunflower, Pea Shooter, Wall Plant, Cherry Bomb, Red Hot Pepper, Corn Cannon, Charm Mushroom, Ice Pea Shooter, Flame Stake, and Gatling Pea Shooter. Sunflowers produce sunshine, walls delay enemies, ice slows, flame stakes enhance passing peas, Gatling shoots five-pea bursts, peppers sweep lanes, corn missiles deal area damage, and charms temporarily convert eligible enemies. Ice Pea and Gatling placement are not blocked by their display-only model timers; the mobile tray only counts down actual placement recharges.

Boss base health and full-health bomb thresholds below apply to **Easy**. Other difficulties scale spawned enemy health, including bosses:

| Boss | Health | Behavior |
| --- | ---: | --- |
| Hammer Shogun | 900 | Survives two direct Cherry Bombs; the third defeats it. Raised hammer gives a 1.35-second warning. |
| Armored Ice Doctor | 1,500 | Defeated by five direct Cherry Bombs. Charged ice orbs hit the first plant in their lane for 42 damage and slow it for 3.6 seconds. |
| Flame Giant | 760 | Warns before an 85-damage strike followed by a 2.5-second burn. |
| Thunder Shogun | 2,800 | Charm-immune. Marks a plant for 2.4 seconds before a lethal lightning strike. |

A full Cherry Bomb deals 300 boss damage. The Shogun takes four direct hits on Normal/Hard/Hell; the Doctor takes six on Normal/Hard and seven on Hell. Other attacks can reduce how many bombs remain necessary. Charge warnings remain at their base duration even when boss attack cooldowns shorten. All synthesized effects and the original looping soundtrack are retained through `AVAudioPlayer` and a playback `AVAudioSession` with mixing enabled. Audio players are prepared before use; activation/playback failures are reported, and players rebuild after an iOS media-services reset.

## Tests

Press **⌘U** in Xcode, or choose an installed simulator (list them with `xcrun simctl list devices available`):

```sh
xcodebuild -project MoonbridgeGarden.xcodeproj -scheme MoonbridgeGarden \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -derivedDataPath DerivedData -parallel-testing-enabled NO test
```

The unit suite carries over gameplay and projection coverage, including boss bomb thresholds, freeze/slow, fire conversions, charm, difficulty, and starting resources. Additional tests verify scaled scheduled-boss durability, frost effects on sunflower timing/income, Hell's double invasion, and the new enemy artwork/animation states. Mobile tests cover lifecycle pausing, phone/tablet coordinate mapping, and rendering populated garden scenes with hazards at three mobile sizes. UI tests check the displayed and actual starting resources for every difficulty, touch planting, scenery/paused taps, scrolling to the final seed, and background/resume. UI tests terminate the game at the end.

## Project structure

- `MoonbridgeGarden/`: independent game model, garden Canvas renderer, iOS view/lifecycle, and iOS audio adapter.
- `MoonbridgeGardenTests/`: gameplay, projection, rendering, and lifecycle unit tests.
- `MoonbridgeGardenUITests/`: touch and app lifecycle smoke test.
- `MoonbridgeGarden.xcodeproj/`: app, unit-test, and UI-test targets with a shared scheme.
- `Tools/GenerateAppIcon.swift`: reproducible, original code-drawn gateway-and-sprout icon. Run `swift Tools/GenerateAppIcon.swift` on macOS to regenerate the included PNG.

## Verification

The September 6 Mac sync passed **47 tests on iPhone 17 Pro (iOS 26.5)** and **47 tests on iPad Pro 11-inch M5 (iPadOS 26.5)**. The signed physical-device Release build also passed. Reviewed the new enemy contact sheet, populated gardens with hazards at three mobile sizes, and the native iPad gameplay screenshot. All test apps and simulators were closed. Test screenshots and result bundles are kept locally in ignored verification/build folders.

**Build 2 (sound fix)** passed all 51 iPad simulator tests, including real audio-player startup, mute/unmute, media-reset recovery, and the Test Sound UI. The signed Release update was installed on the connected iPad Pro 13-inch M5. Its on-device launch diagnostics reported **Speaker, 40% media volume, audio ready, music playing**. These confirm the audio session/player state, not an independent acoustic recording. The launch-check process exited cleanly. No App Store upload is part of this workflow.

The macOS files in the parent project are unchanged. Future gameplay changes must be copied deliberately between the two projects. Device signing, physical-device audio testing, and App Store distribution are separate from the simulator port.
