# Zombies vs Plants — Moonbridge Garden

A native macOS garden-defense game made with SwiftUI, original code-drawn visuals, and synthesized sound. This edition takes place in a bright fantasy Japanese-style garden of moss, stepping stones, water, lanterns, bamboo, maple leaves, and a torii-inspired moonbridge gate. All characters, artwork, animation, music-free sound effects, and gameplay code are original; there are no downloaded assets or third-party packages.

## Run on macOS

Requires macOS 14 or newer and Xcode 16 or newer.

- Double-click **Run Game.command** in Finder, or
- open Terminal in this folder and run `swift run`, or
- open `Package.swift` in Xcode, select the **ZombiesVsPlants** scheme, and press ⌘R.

## How to play

1. Choose a difficulty at the start screen, then press **Start Level**. Every mode begins with **3,000 sunshine**. **Easy** uses the base enemy schedule and speed, **Normal** adds extra samurai and makes them 12% faster, **Hard** adds more extra samurai and makes them 28% faster, and **Hell** is an explicitly labeled extreme challenge with a bounded high-volume schedule and 55% faster enemies. Bosses and victory conditions remain unchanged.
2. Each new garden rolls a bounded, seeded water-lane layout. Water lanes are decorative channels with ripples and bridge cues; plants, projectiles, enemies, and bosses can all interact across them, so no layout blocks required play. Choose one of the ten original defenders—Sunflower, Pea Shooter, **Ice Pea Shooter**, **Flame Stake**, **Gatling Pea Shooter**, Wall Plant, Cherry Bomb, Red Hot Pepper, Corn Cannon, or **Charm Mushroom**—then click an empty garden square.
3. Sunflowers automatically add 25 sunshine. Pea Shooters fire down their lane, Ice Pea Shooters fire blue-white ice peas that deal 18 damage and slow any enemy (including bosses) for 3.5 seconds. Gatling Pea Shooters cost 350 sunshine and rapidly fire five ordinary peas per burst. Ice Pea and Gatling cards show display-only countdowns after placement, but those timers never block another placement; Flame Stake has no cooldown or countdown at all. Sunlight and empty-cell rules still apply. Wall Plants block attackers, Cherry Bombs hit enemies in a nearby three-row area after a short visible fuse and six-second recharge, and Red Hot Peppers charge briefly before sweeping a red flame through their entire row (eight-second recharge).
4. A Flame Stake costs 200 sunshine and has no cooldown. It is a stationary lane amplifier: ordinary peas crossing it become flaming peas with +20 impact damage and a 2-second enemy burn. Ice Peas crossing it become bright steam-flame peas; they keep their 3.5-second slow and also gain the fire bonus and burn. The stake shows animated wood and fire, while conversion and hits produce flame/steam particles and synthesized cues.
5. A Corn Cannon costs 300 sunshine and has an 18-second cooldown. Place it first; then click its seed card again to enter placement mode for another cannon, or click any lawn grid to choose a target. A corn missile follows a visible arcing trail and explodes near that target, clearing ordinary samurai in a three-row area and damaging bosses.
6. Charm Mushroom costs 175 sunshine and has a 12-second cooldown. It briefly charges, marks the nearest eligible enemy in its lane, and converts a scout, armored samurai, Dancer Samurai, Hammer Shogun, Armored Ice Doctor, or Flame Giant into an ally for eight seconds. The ally turns around, walks right, and attacks nearby uncharmed enemies. Only the Thunder Shogun is charm-immune; its health bar visibly says **CHARM IMMUNE**.
7. A playful **Mischievous Tanuki** appears once during a run as a reversible garden trick: for four seconds it disguises itself like a plant card and shows a clear **TANUKI TRICK** banner. It never removes plants or sunshine; the card confusion ends automatically and normal controls recover.
7. Survive three increasingly difficult waves of fantasy samurai scouts, armored samurai, Dancer Samurai, and four late-wave bosses. If an enemy crosses the red moonbridge gate at the far left, the garden is lost.

## Final-wave bosses

- **Hammer Shogun:** 900 boss health. A direct Cherry Bomb deals 300 boss damage, so the shogun survives the first two direct blasts and is defeated by the third if it started at full health. Its raised, glowing hammer provides a 1.35-second warning before a heavy plant strike.
- **Armored Ice Doctor:** 1,500 boss health. It takes five full direct Cherry Bomb hits to defeat from full health. The doctor periodically stops and visibly charges an ice orb before launching it left along its lane. An orb deals 42 damage to the first plant it reaches and coats that plant in frost, slowing its actions for 3.6 seconds.
- **Flame Giant:** 760 boss health and a slow, fire-wreathed silhouette. It pauses with a bright **FLAME STRIKE** warning before hitting its blocking plant for 85 damage, then applies a 2.5-second burn that deals damage over time. Ice Pea Shooters slow it normally; an ice hit adds a blue frost burst against its warm orange flames. Charm Mushroom can convert it because only the Thunder Shogun is charm-immune.
- **Thunder Shogun:** 2,800 boss health—the toughest enemy in the garden. It selects one plant, marks that grid with a lightning target, and charges for 2.4 seconds with a visible bolt and warning cue. The lightning then destroys the marked plant regardless of its remaining health. Move your defenses or fire the Corn Cannon while the warning is active.

Bosses can also be damaged by Pea Shooters and Ice Pea Shooters, so the number of bombs still needed may decrease during normal play. Health bars, named boss labels, warning glows, projectile trails, frost/steam effects, impact particles, and distinct synthesized cues keep the attacks readable.

The **Dancer Samurai** is a family-friendly ordinary enemy variant that can appear in all three waves. Each wave has its own hard five-enemy generation cap, so at most five dancers appear in wave one, five in wave two, and five in wave three. Its visible fan-and-step dance periodically gives it a short speed burst with a rhythm cue and a “DANCE DASH” ring. Charm Mushroom can convert it, after which the dancing samurai becomes an ally and attacks another enemy instead. Charm also works on the two earlier bosses; their boss special attacks pause while they are allied. The Thunder Shogun alone remains immune.

The Red Hot Pepper instantly clears ordinary samurai in its row once its warning animation completes. It deals 210 damage to the Hammer Shogun and 180 damage to the Armored Ice Doctor; these are separate from Cherry Bomb damage, so the exact three-bomb/five-bomb boss rules remain intact when testing Cherry Bombs alone. A Corn Cannon deals 240 damage to any boss in its blast area, giving it a strong but bounded role against the Thunder Shogun.

Use **Pause** (or press **P**) to stop and resume the simulation, and **Sound On/Off** to mute effects. The seed tray is vertically scrollable so every plant card remains reachable in smaller windows.
