param([Parameter(Mandatory=$true)][string]$GameDir)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$game = (Resolve-Path -LiteralPath $GameDir).Path
$gameJar = Join-Path $game 'projectzomboid.jar'
$classes = Join-Path $root 'build/test-tools'
New-Item -ItemType Directory -Path $classes -Force | Out-Null
& javac -d $classes (Join-Path $root 'tests/tools/CheckLua.java')
if ($LASTEXITCODE -ne 0) { throw 'Test runner compilation failed' }
$sp = Join-Path $root 'mods/MobileAutomotiveDistractions/42/media/lua'
$mp = Join-Path $root 'mods/MADMultiplayerProbe/42/media/lua'
$java = Join-Path $game 'jre64/bin/java.exe'
Push-Location $game
try {
    & $java -cp "$classes;$gameJar" CheckLua "$root/tests/singleplayer/rig-fixture.lua" "$sp/shared/MADSteering.lua" "$sp/client/MADRig.lua" "$root/tests/singleplayer/rig-run.lua"
    if ($LASTEXITCODE -ne 0) { throw 'Single-player fixture failed' }
    & $java -cp "$classes;$gameJar" CheckLua "$root/tests/multiplayer/rig-server-fixture.lua" "$mp/shared/MADMPRigState.lua" "$mp/server/MADMPRigServer.lua" "$root/tests/multiplayer/client-test-run.lua"
    if ($LASTEXITCODE -ne 0) { throw 'Multiplayer server fixture failed' }
    & $java -cp "$classes;$gameJar" CheckLua "$root/tests/multiplayer/rig-client-fixture.lua" "$mp/shared/MADSteering.lua" "$mp/client/MADMPRigClient.lua" "$root/tests/multiplayer/client-test-run.lua"
    if ($LASTEXITCODE -ne 0) { throw 'Multiplayer client fixture failed' }
} finally { Pop-Location }
