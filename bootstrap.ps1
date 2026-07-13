# ============================================================================
#  bootstrap.ps1 — symlink dotfiles into their expected locations
#
#  Run from an elevated PowerShell prompt:
#      Set-ExecutionPolicy -Scope Process Bypass
#      .\bootstrap.ps1
#
#  On Windows, creating symlinks requires either:
#    - Administrator privileges, OR
#    - Developer Mode enabled (Settings → Privacy & Security → For developers)
#
#  Existing files at the target paths are backed up to *.bak before linking.
# ============================================================================

[CmdletBinding()]
param(
    [switch]$Force  # overwrite existing .bak files without prompting
)

$ErrorActionPreference = 'Stop'
$repoRoot = $PSScriptRoot

# Source -> Target mapping. Target uses environment variables so this works
# on any Windows user account.
$links = @(
    @{
        Source = Join-Path $repoRoot 'nvim'
        Target = Join-Path $env:LOCALAPPDATA 'nvim'
        Kind   = 'Directory'
    },
    @{
        Source = Join-Path $repoRoot 'wezterm\.wezterm.lua'
        Target = Join-Path $env:USERPROFILE '.wezterm.lua'
        Kind   = 'File'
    },
    @{
        Source = Join-Path $repoRoot 'starship\starship.toml'
        Target = Join-Path $env:USERPROFILE '.config\starship.toml'
        Kind   = 'File'
    }
)

function Backup-Existing($path) {
    if (Test-Path $path) {
        $bak = "$path.bak"
        if ((Test-Path $bak) -and -not $Force) {
            $ans = Read-Host "Backup '$bak' already exists. Overwrite? (y/N)"
            if ($ans -ne 'y') { Write-Host "Skipping $path" ; return $false }
        }
        if (Test-Path $bak) { Remove-Item $bak -Force -Recurse }
        Move-Item $path $bak
        Write-Host "Backed up existing $path -> $bak"
    }
    return $true
}

foreach ($link in $links) {
    $source = $link.Source
    $target = $link.Target
    $kind   = $link.Kind

    if (-not (Test-Path $source)) {
        Write-Warning "Source missing, skipping: $source"
        continue
    }

    # Ensure parent dir of target exists
    $parent = Split-Path $target -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    if (Test-Path $target) {
        $isLink = (Get-Item $target -Force).LinkType -ne $null
        if ($isLink) {
            Write-Host "Symlink already exists at $target — recreating"
            Remove-Item $target -Force -Recurse
        } else {
            if (-not (Backup-Existing $target)) { continue }
        }
    }

    if ($kind -eq 'Directory') {
        New-Item -ItemType SymbolicLink -Path $target -Target $source | Out-Null
    } else {
        New-Item -ItemType SymbolicLink -Path $target -Target $source | Out-Null
    }
    Write-Host "Linked $target -> $source"
}

Write-Host ""
Write-Host "Done. Restart any open WezTerm/Neovim windows to pick up configs."
Write-Host ""
Write-Host "If symlinks failed with 'permission denied':"
Write-Host "  - Run this script from an elevated PowerShell, OR"
Write-Host "  - Enable Developer Mode (Settings -> Privacy & Security -> For developers)"
