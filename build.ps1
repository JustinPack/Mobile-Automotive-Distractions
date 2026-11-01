param([Parameter(Mandatory=$true)][string]$ZombieBuddyJar)
$ErrorActionPreference = 'Stop'
$zb = (Resolve-Path -LiteralPath $ZombieBuddyJar).Path
$root = $PSScriptRoot
$build = Join-Path $root 'build'
foreach ($mode in @('singleplayer', 'multiplayer')) {
    $classes = Join-Path $build "$mode/classes"
    $stubs = Join-Path $build "$mode/stubs"
    if (Test-Path (Join-Path $build $mode)) { Remove-Item (Join-Path $build $mode) -Recurse -Force }
    New-Item -ItemType Directory -Path $classes,$stubs -Force | Out-Null
    $stubSources = @(Get-ChildItem (Join-Path $root 'java/singleplayer/compile-stubs') -Filter '*.java' -Recurse | ForEach-Object FullName)
    if ($mode -eq 'multiplayer') { $stubSources += @(Get-ChildItem (Join-Path $root 'java/multiplayer/stubs') -Filter '*.java' -Recurse | ForEach-Object FullName) }
    & javac -d $stubs $stubSources
    if ($LASTEXITCODE -ne 0) { throw "$mode stub compilation failed" }
    $sources = @(Get-ChildItem (Join-Path $root "java/$mode/src") -Filter '*.java' -Recurse | ForEach-Object FullName)
    & javac -cp "$zb;$stubs" -d $classes $sources
    if ($LASTEXITCODE -ne 0) { throw "$mode compilation failed" }
    $target = if ($mode -eq 'singleplayer') { 'mods/MobileAutomotiveDistractions/42/media/java/MobileAutomotiveDistractions.jar' } else { 'mods/MADMultiplayerProbe/42/media/java/MADMPServerTest.jar' }
    & jar cf (Join-Path $root $target) -C $classes .
    if ($LASTEXITCODE -ne 0) { throw "$mode packaging failed" }
    Write-Host "Built $target"
}
