# Install kermit skill for Claude Code (Windows)
$ErrorActionPreference = "Stop"

$skillDir = Join-Path $HOME ".claude\skills\kermit"
$scriptDir = $PSScriptRoot

Write-Host "Installing kermit -> $skillDir"

New-Item -ItemType Directory -Force -Path $skillDir | Out-Null
Copy-Item "$scriptDir\SKILL.md" "$skillDir\SKILL.md" -Force

$refsDir = Join-Path $scriptDir "refs"
if (Test-Path $refsDir) {
    Copy-Item $refsDir "$skillDir\refs" -Recurse -Force
}

$prefFile = Join-Path $scriptDir "pref.json"
if (Test-Path $prefFile) {
    Copy-Item $prefFile "$skillDir\pref.json" -Force
}

Write-Host "Done. Use /kermit in any Claude Code session."
