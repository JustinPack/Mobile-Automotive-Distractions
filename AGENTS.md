# Developer guidance

## Project and layout

M.A.D. targets Project Zomboid Build 42 and requires ZombieBuddy. `mods/MobileAutomotiveDistractions` is the single-player distribution. `mods/MADMultiplayerProbe` is the multiplayer distribution; the identifier is historical and must remain stable for existing installations. Enable only one at a time. Lua and `mod.info` in those directories are the shipping sources. `java/singleplayer/src/mad/rig` and `java/multiplayer/src/mad/mp` are the sources of the corresponding JARs under each mod's `42/media/java/` directory. Rebuild the matching JAR after changing Java; do not bundle Project Zomboid or ZombieBuddy binaries.

The player configures controls in real time. Setting the accelerator while the parking brake is off starts the car. A severe speed drop can knock the wedge loose. The driver seat is blocked while rigged. Actual wedge/rope/plank/tape and horn skill/screwdriver requirements are mandatory. Do not reintroduce debug menu entries or free materials.

## Multiplayer architecture and limits

The server validates rig commands and inventory changes, stores rig state, broadcasts updates, and assigns a client physics lease. A designated client runs vehicle physics using the game's ordinary synchronization; this is not server-authoritative simulation. An absent or disconnected controlling client stalls the rig; unloaded vehicles do not run. `PassengerMapPatch` bypasses one invalid-chunk check only for leased vehicles with no occupants. A passenger may cause braking. Treat client input, authority, recovery, proximity, driver-seat restrictions, restarts, disconnects and vehicle destruction as security and consistency boundaries.

The horn uses vanilla behavior where available; battery drain is an approximation while loaded. The accelerator collision proxy detects a 90% speed drop within 500 ms above 5 km/h and can miss collisions or misfire. Real multiplayer testing has confirmed two-client movement sync and an impact stop; material transfers/recovery, horn sync, passengers, late joins, disconnects and restart recovery still need in-game verification. Do not describe those as verified.

## Build and tests

Use JDK 21 and a local ZombieBuddy installation. Run `./build.ps1 -ZombieBuddyJar <path-to-ZombieBuddy.jar>` in PowerShell. It builds both M.A.D. JARs using compile-only stubs and ZombieBuddy's classes. The files in `mods/` are distribution artifacts; preserve mod IDs and avoid silently checking in local libraries, save files, passwords, or logs.

Run `./test.ps1 -GameDir <path-to-ProjectZomboid>` to execute the Lua fixtures using the locally installed game's runtime. These mocked tests do not replace an in-game test. When changing physics or network behavior, test dedicated-server startup and two clients, inspect both logs, and record what was actually observed. Test inventory loss/recovery and interrupted states separately. Do not include game files or reverse-engineered game bytecode in this repository.

Consult current vanilla behavior and ZombieBuddy APIs when changing integration points. Patches can break on a game or ZombieBuddy update. The included JARs reflect the tested Build 42.21 prototype; builds for other versions require validation. Repository source is under The Unlicense; third-party software retains its own license.
