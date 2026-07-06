# Install kermit skill for Claude Code (Windows)
$ErrorActionPreference = "Stop"

$repoRaw = "https://raw.githubusercontent.com/ndisisnd/kermit/main"
$skillDir = Join-Path $HOME ".claude\skills\kermit"
$refs = @("init.md", "changelog-protocol.md", "changelog-reset.md")
$workflowRefs = @("release.yml", "deploy.yml")   # scaffolding templates under refs/workflows/

# Resolve a local checkout dir if run from one; when piped via `irm ... | iex` there is none, so download.
$scriptDir = $PSScriptRoot

# Fetch a repo-relative path to a destination — copy from the local checkout if present, else download.
function Get-KermitFile($rel, $dest) {
    $local = if ($scriptDir) { Join-Path $scriptDir $rel } else { $null }
    if ($local -and (Test-Path $local)) {
        Copy-Item $local $dest -Force
    } else {
        Invoke-WebRequest -Uri "$repoRaw/$($rel -replace '\\','/')" -OutFile $dest -UseBasicParsing
    }
}

Write-Host "Installing kermit -> $skillDir"

# Start from a clean refs dir so files dropped in an upgrade don't linger.
$refsDir = Join-Path $skillDir "refs"
if (Test-Path $refsDir) { Remove-Item $refsDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $refsDir | Out-Null

Get-KermitFile "SKILL.md" "$skillDir\SKILL.md"
foreach ($r in $refs) {
    Get-KermitFile "refs\$r" "$skillDir\refs\$r"
}
# Workflow scaffolding templates live in the refs\workflows\ subdir.
$workflowsDir = Join-Path $refsDir "workflows"
New-Item -ItemType Directory -Force -Path $workflowsDir | Out-Null
foreach ($w in $workflowRefs) {
    Get-KermitFile "refs\workflows\$w" "$workflowsDir\$w"
}
# pref.json is a template and optional — skip silently if it can't be fetched.
try { Get-KermitFile "pref.json" "$skillDir\pref.json" } catch {}

Write-Host "Done. Installed -> $skillDir"
Write-Host ""
Write-Host "kermit formats and runs git commits using Conventional Commits — emoji prefix,"
Write-Host "point-form file bodies, BREAKING CHANGE footer — and keeps CHANGELOG.md in sync."
Write-Host ""
Write-Host '-> Run "/kermit --init" in any local repo to initialise its preferences.'
Write-Host "-> Tailor kermit to your needs by editing $skillDir\SKILL.md."
Write-Host ""
Write-Host "Thank you JC ❤️" -ForegroundColor Magenta
