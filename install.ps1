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

Write-Host "Done. Installed -> $skillDir"
Write-Host ""
Write-Host "kermit formats and runs git commits using Conventional Commits — emoji prefix,"
Write-Host "point-form file bodies, BREAKING CHANGE footer — and keeps CHANGELOG.md in sync."
Write-Host ""
Write-Host '-> Run "/kermit --init" in any local repo to initialise its preferences.'
Write-Host "-> Tailor kermit to your needs by editing $skillDir\SKILL.md."
Write-Host ""
Write-Host "Thank you JC ❤️" -ForegroundColor Magenta
