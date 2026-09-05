# Zombies vs Plants — Moonbridge Garden

A native macOS garden-defense game made with SwiftUI, original code-drawn visuals, and synthesized sound. This edition takes place in a bright fantasy Japanese-style garden of moss, stepping stones, water, lanterns, bamboo, maple leaves, and a torii-inspired moonbridge gate. All characters, artwork, animation, music-free sound effects, and gameplay code are original; there are no downloaded assets or third-party packages.

## Run on macOS

Requires macOS 14 or newer and Xcode 16 or newer.

- Double-click **Run Game.command** in Finder, or
- open Terminal in this folder and run `swift run`, or
- open `Package.swift` in Xcode, select the **ZombiesVsPlants** scheme, and press ⌘R.

## How to play

1. Press **Start Level**. Every new game begins with **1,000 sunshine**, shown at the top of the seed tray.
2. Choose one of the six original defenders—Sunflower, Pea Shooter, Wall Plant, Cherry Bomb, **Red Hot Pepper**, or **Corn Cannon**—then click an empty garden square.
3. Sunflowers automatically add 25 sunshine. Pea Shooters fire down their lane, Wall Plants block attackers, Cherry Bombs hit enemies in a nearby three-row area after a short visible fuse and six-second recharge, and Red Hot Peppers charge briefly before sweeping a red flame through their entire row (eight-second recharge).
4. A Corn Cannon costs 300 sunshine and has an 18-second cooldown. Place it first; then click its seed card again to enter placement mode for another cannon, or click any lawn grid to choose a target. A corn missile follows a visible arcing trail and explodes near that target, clearing ordinary samurai in a three-row area and damaging bosses.
5. Survive three increasingly difficult waves of fantasy samurai scouts, armored samurai, and three final-wave bosses. If an enemy crosses the red moonbridge gate at the far left, the garden is lost.

## Final-wave bosses

- **Hammer Shogun:** 900 boss health. A direct Cherry Bomb deals 300 boss damage, so the shogun survives the first two direct blasts and is defeated by the third if it started at full health. Its raised, glowing hammer provides a 1.35-second warning before a heavy plant strike.
- **Armored Ice Doctor:** 1,500 boss health. It takes five full direct Cherry Bomb hits to defeat from full health. The doctor periodically stops and visibly charges an ice orb before launching it left along its lane. An orb deals 42 damage to the first plant it reaches and coats that plant in frost, slowing its actions for 3.6 seconds.
- **Thunder Shogun:** 2,800 boss health—the toughest enemy in the garden. It selects one plant, marks that grid with a lightning target, and charges for 2.4 seconds with a visible bolt and warning cue. The lightning then destroys the marked plant regardless of its remaining health. Move your defenses or fire the Corn Cannon while the warning is active.

Bosses can also be damaged by Pea Shooters, so the number of bombs still needed may decrease during normal play. Health bars, named boss labels, warning glows, projectile trails, frost effects, impact particles, and distinct synthesized cues keep the attacks readable.

The Red Hot Pepper instantly clears ordinary samurai in its row once its warning animation completes. It deals 210 damage to the Hammer Shogun and 180 damage to the Armored Ice Doctor; these are separate from Cherry Bomb damage, so the exact three-bomb/five-bomb boss rules remain intact when testing Cherry Bombs alone. A Corn Cannon deals 240 damage to any boss in its blast area, giving it a strong but bounded role against the Thunder Shogun.

Use **Pause** to stop the simulation and **Sound On/Off** to mute effects.
