# M.A.D. — Mobile Automotive Distractions

Rig an unattended running vehicle to drive away, sound its horn, and distract zombies in Project Zomboid Build 42. Includes separate single-player and experimental multiplayer mods.

## Play

1. Install [ZombieBuddy](https://steamcommunity.com/sharedfiles/filedetails/?id=3619862853), including its one-time installation, and restart the game.
2. Copy one folder from `mods/` into your `Zomboid/mods/` folder, or install it through Steam Workshop when available. Enable ZombieBuddy and **one** M.A.D. version: `MobileAutomotiveDistractions` for single-player or `MADMultiplayerProbe` for multiplayer.
3. Start a vehicle normally, stop and exit at the driver's door, then right-click it and choose **Rig as distraction**. A stone or wrench wedges the accelerator; rope or a plank and duct tape can restrain the steering. A screwdriver and level 3 Electrical or Mechanics are required for the horn. See the mod's included README for controls and recovery.

For multiplayer, install ZombieBuddy and the multiplayer version on the server and every client. Review ZombieBuddy's Java-mod approval dialog when it appears.

## Develop

- `mods/`: the game-ready Lua, metadata, and compiled M.A.D. Java patches.
- `java/singleplayer/` and `java/multiplayer/`: source code for those patches and minimal compile-time stubs.
- `tests/`: Lua fixtures and a runner using the game's Kahlua runtime.
- `assets/`: project title art.
- `AGENTS.md`: architecture, testing, and development guidance.

Build and test instructions are in [AGENTS.md](AGENTS.md). Multiplayer movement has been observed syncing between two clients, but passengers, disconnects, restarts, inventory recovery, and horn synchronization need more testing. Simulation requires an eligible connected client. This is not server-authoritative physics.

## License

The project's own code is dedicated to the public domain under [The Unlicense](LICENSE). Project Zomboid, ZombieBuddy, and other third-party dependencies remain under their respective licenses; they are not included in this dedication.
