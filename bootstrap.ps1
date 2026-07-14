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
    },
    @{
        Source = Join-Path $repoRoot 'powershell\Microsoft.PowerShell_profile.ps1'
        Target = $PROFILE
        Kind   = 'File'
    }
)

# ============================================================================
#  Dependency table — CLI tools/fonts this dotfiles setup expects.
#  Re-run any time: missing tools are installed, already-installed ones are
#  skipped. Tries choco first (if present), then winget, then falls back to
#  prompting the user with a manual download link.
#
#  Check: a scriptblock returning $true when the tool is already present.
# ============================================================================
$dependencies = @(
    @{ Name = 'git';         Check = { Get-Command git -ErrorAction SilentlyContinue };         Choco = 'git';                  Winget = 'Git.Git';                              Url = 'https://git-scm.com/download/win' }
    @{ Name = 'neovim';      Check = { Get-Command nvim -ErrorAction SilentlyContinue };         Choco = 'neovim';               Winget = 'Neovim.Neovim';                        Url = 'https://github.com/neovim/neovim/releases' }
    @{ Name = 'oh-my-posh';  Check = { Get-Command oh-my-posh -ErrorAction SilentlyContinue };   Choco = 'oh-my-posh';           Winget = 'JanDeDobbeleer.OhMyPosh';              Url = 'https://ohmyposh.dev/docs/installation/windows' }
    @{ Name = 'fd';          Check = { Get-Command fd -ErrorAction SilentlyContinue };            Choco = 'fd';                   Winget = 'sharkdp.fd';                           Url = 'https://github.com/sharkdp/fd/releases' }
    @{ Name = 'ripgrep';     Check = { Get-Command rg -ErrorAction SilentlyContinue };            Choco = 'ripgrep';              Winget = 'BurntSushi.ripgrep.MSVC';              Url = 'https://github.com/BurntSushi/ripgrep/releases' }
    @{ Name = 'fzf';         Check = { Get-Command fzf -ErrorAction SilentlyContinue };           Choco = 'fzf';                  Winget = 'junegunn.fzf';                         Url = 'https://github.com/junegunn/fzf/releases' }
    @{ Name = 'zoxide';      Check = { Get-Command zoxide -ErrorAction SilentlyContinue };        Choco = 'zoxide';               Winget = 'ajeetdsouza.zoxide';                   Url = 'https://github.com/ajeetdsouza/zoxide/releases' }
    @{ Name = 'bat';         Check = { Get-Command bat -ErrorAction SilentlyContinue };           Choco = 'bat';                  Winget = 'sharkdp.bat';                          Url = 'https://github.com/sharkdp/bat/releases' }
    @{ Name = 'lazygit';     Check = { Get-Command lazygit -ErrorAction SilentlyContinue };       Choco = 'lazygit';              Winget = 'JesseDuffield.lazygit';                Url = 'https://github.com/jesseduffield/lazygit/releases' }
    @{ Name = 'file';        Check = { Get-Command file -ErrorAction SilentlyContinue };          Choco = 'file';                 Winget = $null;                                  Url = 'https://community.chocolatey.org/packages/file' }
    @{ Name = 'yazi';        Check = { Get-Command yazi -ErrorAction SilentlyContinue };           Choco = $null;                  Winget = 'sxyazi.yazi';                          Url = 'https://yazi-rs.github.io/docs/installation' }
    @{ Name = 'glazewm';     Check = { Get-Command glazewm -ErrorAction SilentlyContinue };       Choco = 'glazewm';              Winget = 'glzr-io.glazewm';                      Url = 'https://github.com/glzr-io/glazewm/releases' }
    @{ Name = 'C compiler (WinLibs)'; Check = { (Get-Command cc -ErrorAction SilentlyContinue) -or (Get-Command gcc -ErrorAction SilentlyContinue) }; Choco = $null; Winget = 'BrechtSanders.WinLibs.POSIX.UCRT'; Url = 'https://winlibs.com' }
)

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-Dependencies {
    $hasChoco  = [bool](Get-Command choco -ErrorAction SilentlyContinue)
    $hasWinget = [bool](Get-Command winget -ErrorAction SilentlyContinue)
    $isAdmin   = Test-Admin

    if (($hasChoco -or $hasWinget) -and -not $isAdmin) {
        Write-Warning "Not running elevated — choco/winget installs may fail. Re-run as Administrator if installs below fail."
    }

    foreach ($dep in $dependencies) {
        $name = $dep.Name
        if (& $dep.Check) {
            Write-Host "[ok]      $name already installed" -ForegroundColor Green
            continue
        }

        Write-Host "[missing] $name" -ForegroundColor Yellow

        $installed = $false
        if ($hasChoco -and $dep.Choco) {
            Write-Host "          installing via choco install $($dep.Choco) -y ..."
            choco install $dep.Choco -y | Out-Null
            $installed = [bool](& $dep.Check)
        }

        if (-not $installed -and $hasWinget -and $dep.Winget) {
            Write-Host "          installing via winget install --id=$($dep.Winget) -e ..."
            winget install --id=$dep.Winget -e --accept-package-agreements --accept-source-agreements | Out-Null
            $installed = [bool](& $dep.Check)
        }

        if ($installed) {
            Write-Host "[ok]      $name installed" -ForegroundColor Green
        } else {
            Write-Warning "$name could not be installed automatically (no choco/winget package, or install failed)."
            Write-Host "          Download manually: $($dep.Url)" -ForegroundColor Cyan
        }
    }
}

Write-Host "== Checking dependencies ==" -ForegroundColor Cyan
Install-Dependencies

# PowerShell Gallery modules aren't installed via choco/winget — handle separately.
$psModules = @('Terminal-Icons')
foreach ($mod in $psModules) {
    if (Get-Module -ListAvailable -Name $mod) {
        Write-Host "[ok]      PS module '$mod' already installed" -ForegroundColor Green
    } else {
        Write-Host "[missing] PS module '$mod' — installing via Install-Module ..." -ForegroundColor Yellow
        try {
            Install-Module -Name $mod -Repository PSGallery -Scope CurrentUser -Force -ErrorAction Stop
            Write-Host "[ok]      PS module '$mod' installed" -ForegroundColor Green
        } catch {
            Write-Warning "Could not install PS module '$mod': $_"
        }
    }
}
Write-Host ""
Write-Host "== Linking dotfiles ==" -ForegroundColor Cyan

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
