<#
.SYNOPSIS
  claude-code-team-stack: setup on Windows.

.DESCRIPTION
  Recommended: run Claude Code inside WSL2. On native Windows the LSP plugins
  (jdtls-lsp, typescript-lsp) currently fail to start the language server.
  The rest of the stack works fine.

  Default mode -> checks/installs WSL2 and prints the next steps.
  -Native      -> installs the stack on native Windows, WITHOUT the LSP plugins.

.EXAMPLE
  .\setup-claude-stack-windows.ps1
  .\setup-claude-stack-windows.ps1 -Native -RepoDir C:\dev\my-api
#>
param(
  [switch]$Native,
  [string]$RepoDir = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
function Write-Info($m) { Write-Host "[info] $m" -ForegroundColor Cyan }
function Write-Ok($m)   { Write-Host "[ ok ] $m" -ForegroundColor Green }
function Write-Warn($m) { Write-Host "[warn] $m" -ForegroundColor Yellow }
function Test-Cmd($c)   { [bool](Get-Command $c -ErrorAction SilentlyContinue) }

if (-not $Native) {
  # ---------- Recommended path: WSL2 ----------
  $distros = @()
  if (Test-Cmd 'wsl') {
    $distros = @((wsl.exe -l -q 2>$null) -replace "`0", '' | Where-Object { $_.Trim() })
  }

  if ($distros.Count -eq 0) {
    Write-Warn 'WSL2 with a Linux distribution was not found.'
    $resp = Read-Host 'Install WSL2 with Ubuntu now? Requires admin and a reboot (y/N)'
    if ($resp -match '^[yYsS]') {
      Start-Process powershell -Verb RunAs -ArgumentList 'wsl --install -d Ubuntu' -Wait
      Write-Ok 'Install started. Reboot, open Ubuntu once, then run this script again.'
    } else {
      Write-Info 'No WSL? Run with -Native (full stack except the LSP plugins).'
    }
    exit 0
  }

  Write-Ok "WSL found: $($distros -join ', ')"
  Write-Host @'

Next steps (inside the Ubuntu/WSL terminal):

  1. Install Claude Code in WSL:
       curl -fsSL https://claude.ai/install.sh | bash

  2. Clone your repos INSIDE WSL (e.g. ~/dev), not under /mnt/c:
       mkdir -p ~/dev && cd ~/dev && git clone <repo-url>

  3. Run the setup from the repo root:
       bash <path>/scripts/setup-claude-stack.sh

  Tip: VS Code and IntelliJ open WSL projects normally
  ("WSL" extension in VS Code; WSL as a target in IntelliJ).
'@
  exit 0
}

# ---------- -Native mode (no LSP) ----------
$settings = Join-Path $RepoDir '.claude\settings.json'
if (-not (Test-Path $settings)) { throw "No $settings found. Copy one of the templates into the repo first." }
if (-not (Test-Cmd 'claude')) { throw 'Claude Code not found. Install: irm https://claude.ai/install.ps1 | iex' }
if (-not (Test-Cmd 'git'))    { throw 'git not found. Install: winget install Git.Git' }
if (-not ((Test-Cmd 'python') -or (Test-Cmd 'py'))) {
  Write-Warn 'Python 3 not found (security-guidance needs it). Install: winget install Python.Python.3.12'
}

$cfg = Get-Content $settings -Raw | ConvertFrom-Json

claude plugin marketplace add anthropics/claude-plugins-official *> $null
claude plugin marketplace update claude-plugins-official *> $null

if ($cfg.extraKnownMarketplaces) {
  foreach ($mk in $cfg.extraKnownMarketplaces.PSObject.Properties) {
    $src = $mk.Value.source
    $target = if ($src.repo) { $src.repo } else { $src.url }
    Write-Info "Registering marketplace $target"
    claude plugin marketplace add $target *> $null
  }
}

Push-Location $RepoDir
$failed = @()
foreach ($p in $cfg.enabledPlugins.PSObject.Properties) {
  if (-not $p.Value) { continue }
  if ($p.Name -match '-lsp@') {
    Write-Warn "skipping $($p.Name) (LSP does not work on native Windows yet; use WSL2)"
    continue
  }
  claude plugin install $p.Name --scope project *> $null
  if ($LASTEXITCODE -eq 0) { Write-Ok "plugin $($p.Name)" } else { Write-Warn "failed: $($p.Name)"; $failed += $p.Name }
}
Pop-Location

if ($failed.Count -gt 0) { Write-Warn "Install manually with /plugin: $($failed -join ', ')" }
Write-Warn 'To silence LSP errors, disable them just for you in .claude\settings.local.json:'
Write-Host '  { "enabledPlugins": { "jdtls-lsp@claude-plugins-official": false, "typescript-lsp@claude-plugins-official": false } }'
Write-Ok 'Done. Open Claude Code in the repo and run /plugin to check.'
