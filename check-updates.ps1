# ============================================================================
#  check-updates.ps1 — installed vs latest versions for the tools bootstrap.ps1
#  manages. Checks winget, Chocolatey, GitHub releases and the PowerShell Gallery.
#
#  Read-only: nothing is installed or upgraded. Run from PowerShell:
#      .\check-updates.ps1
#
#  The Update column shows the command to apply each update.
# ============================================================================

$ErrorActionPreference = 'Continue'   # one failing source should not stop the rest

# Kind selects where the version is checked:
#   winget : Id = winget package id
#   choco  : Id = Chocolatey package name
#   github : Id = owner/repo of the release; Cmd = command that prints the version
#   psgal  : Id = PowerShell Gallery module name
#   manual : Cmd = command that prints the version; no online check is made
$tools = @(
    @{ Name = 'Git';            Kind = 'winget'; Id = 'Git.Git' }
    @{ Name = 'Neovim';         Kind = 'winget'; Id = 'Neovim.Neovim' }
    @{ Name = 'Oh My Posh';     Kind = 'winget'; Id = 'JanDeDobbeleer.OhMyPosh' }
    @{ Name = 'fd';             Kind = 'winget'; Id = 'sharkdp.fd' }
    @{ Name = 'ripgrep';        Kind = 'winget'; Id = 'BurntSushi.ripgrep.MSVC' }
    @{ Name = 'fzf';            Kind = 'winget'; Id = 'junegunn.fzf' }
    @{ Name = 'zoxide';         Kind = 'winget'; Id = 'ajeetdsouza.zoxide' }
    @{ Name = 'lazygit';        Kind = 'winget'; Id = 'JesseDuffield.lazygit' }
    @{ Name = 'Yazi';           Kind = 'winget'; Id = 'sxyazi.yazi' }
    @{ Name = 'superfile';      Kind = 'winget'; Id = 'yorukot.superfile' }
    @{ Name = 'GlazeWM';        Kind = 'winget'; Id = 'glzr-io.glazewm' }
    @{ Name = 'WezTerm';        Kind = 'winget'; Id = 'wez.wezterm' }
    @{ Name = 'C compiler';     Kind = 'winget'; Id = 'BrechtSanders.WinLibs.POSIX.UCRT' }
    @{ Name = 'bat';            Kind = 'choco';  Id = 'bat' }
    @{ Name = 'starship';       Kind = 'github'; Id = 'starship/starship';  Cmd = 'starship' }
    @{ Name = 'neru';           Kind = 'github'; Id = 'y3owk1n/neru';       Cmd = 'neru' }
    @{ Name = 'Terminal-Icons'; Kind = 'psgal';  Id = 'Terminal-Icons' }
    @{ Name = 'herdr';          Kind = 'manual'; Cmd = 'herdr' }
)

function Get-Version([string]$text) {
    if ($text -match '(\d+(\.\d+)+)') { return $Matches[1] }
    return $null
}

function Test-Newer([string]$installed, [string]$latest) {
    try { return ([version]$latest -gt [version]$installed) } catch { return ($latest -ne $installed) }
}

# ---- bulk lookups: one call per package manager, not one per tool ----
$wingetAvailable = $false
$wingetList    = @()
$wingetUpgrade = @()
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "== Querying winget ==" -ForegroundColor Cyan
    $wingetAvailable = $true
    $wingetList    = @(winget list --accept-source-agreements 2>$null | ForEach-Object { "$_" -replace "`r", '' })
    $wingetUpgrade = @(winget upgrade --accept-source-agreements 2>$null | ForEach-Object { "$_" -replace "`r", '' })
} else {
    Write-Warning "winget not found; winget tools will be reported as unknown."
}

$chocoInstalled = @{}
$chocoOutdated  = @{}
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Host "== Querying Chocolatey ==" -ForegroundColor Cyan
    foreach ($l in (choco list --local-only --limit-output 2>$null)) {
        $p = "$l" -split '\|'
        if ($p.Count -ge 2) { $chocoInstalled[$p[0]] = $p[1] }
    }
    foreach ($l in (choco outdated --limit-output 2>$null)) {
        $p = "$l" -split '\|'
        if ($p.Count -ge 3) { $chocoOutdated[$p[0]] = $p[2] }
    }
} else {
    Write-Warning "choco not found; choco tools will be reported as unknown."
}

Write-Host "== Querying GitHub, PowerShell Gallery and local tools ==" -ForegroundColor Cyan

$rows = foreach ($t in $tools) {
    $installed = $null
    $latest    = $null
    $update    = ''
    $status    = ''

    switch ($t.Kind) {
        'winget' {
            if (-not $wingetAvailable) { $status = 'unknown (winget missing)'; break }
            $id = [regex]::Escape($t.Id)
            $listLine = $wingetList | Where-Object { $_ -match "\s$id\s+(\S+)" } | Select-Object -First 1
            if ($listLine -and $listLine -match "\s$id\s+v?(\S+)") { $installed = $Matches[1] }
            $upLine = $wingetUpgrade | Where-Object { $_ -match "\s$id\s+\S+\s+(\S+)\s+(winget|msstore)\s*$" } | Select-Object -First 1
            if ($upLine -and $upLine -match "\s$id\s+\S+\s+v?(\S+)\s+(winget|msstore)\s*$") { $latest = $Matches[1] }
            $update = "winget upgrade --id $($t.Id) -e"
            if (-not $installed)     { $status = 'not installed' }
            elseif ($latest)         { $status = 'update available' }
            else                     { $status = 'up to date'; $latest = $installed }
        }
        'choco' {
            $installed = $chocoInstalled[$t.Id]
            $latest    = $chocoOutdated[$t.Id]
            $update    = "choco upgrade $($t.Id) -y"
            if (-not $installed)     { $status = 'not installed' }
            elseif ($latest)         { $status = 'update available' }
            else                     { $status = 'up to date'; $latest = $installed }
        }
        'github' {
            if (Get-Command $t.Cmd -ErrorAction SilentlyContinue) {
                $installed = Get-Version ((& $t.Cmd --version 2>$null) -join ' ')
            }
            try {
                $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$($t.Id)/releases/latest" -TimeoutSec 20
                $latest = Get-Version $rel.tag_name
            } catch {
                $latest = $null
            }
            $update = "re-run the $($t.Name) install line in README.md"
            if (-not $installed)                          { $status = 'not installed' }
            elseif (-not $latest)                         { $status = 'unknown (GitHub unreachable)' }
            elseif (Test-Newer $installed $latest)        { $status = 'update available' }
            else                                          { $status = 'up to date' }
        }
        'psgal' {
            $local = Get-Module -ListAvailable -Name $t.Id | Sort-Object Version -Descending | Select-Object -First 1
            if ($local) { $installed = $local.Version.ToString() }
            try {
                # The feed is not version-sorted, so take the highest version explicitly.
                $feed = Invoke-RestMethod -Uri "https://www.powershellgallery.com/api/v2/FindPackagesById()?id='$($t.Id)'" -TimeoutSec 20
                $latest = @($feed | ForEach-Object { Get-Version $_.properties.Version } |
                    Where-Object { $_ } | Sort-Object { [version]$_ } -Descending)[0]
            } catch {
                $latest = $null
            }
            $update = "Install-Module $($t.Id) -Scope CurrentUser -Force"
            if (-not $installed)                          { $status = 'not installed' }
            elseif (-not $latest)                         { $status = 'unknown (PSGallery unreachable)' }
            elseif (Test-Newer $installed $latest)        { $status = 'update available' }
            else                                          { $status = 'up to date' }
        }
        'manual' {
            if (Get-Command $t.Cmd -ErrorAction SilentlyContinue) {
                $installed = Get-Version ((& $t.Cmd --version 2>$null) -join ' ')
            }
            $latest = $null
            $update = "$($t.Cmd) update"
            if (-not $installed) { $status = 'not installed' } else { $status = 'no online check (self-updating)' }
        }
    }

    [pscustomobject]@{
        Tool      = $t.Name
        Installed = if ($installed) { $installed } else { '-' }
        Latest    = if ($latest) { $latest } else { '-' }
        Status    = $status
        Update    = if ($status -eq 'update available' -or $t.Kind -eq 'manual') { $update } else { '' }
    }
}

Write-Host ""
$rows | Format-Table -AutoSize -Wrap | Out-String | Write-Host

$pending = @($rows | Where-Object { $_.Status -eq 'update available' })
if ($pending.Count -eq 0) {
    Write-Host "[ok] Nothing to update." -ForegroundColor Green
} else {
    Write-Host "[update] $($pending.Count) update(s) available." -ForegroundColor Yellow
}
