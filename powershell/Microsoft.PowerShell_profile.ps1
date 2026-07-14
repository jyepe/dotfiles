# ============================================================================
#  Refresh PATH from the registry (Machine + User)
#  A shell launched from a long-running parent (explorer.exe / GlazeWM /
#  Alacritty) inherits that parent's in-memory PATH, which goes stale after
#  installing new software (e.g. Python). Rebuild PATH from the persisted
#  registry values so every new shell sees current entries, while preserving
#  any session-only entries a parent injected. Dedupes (ignoring trailing \).
#  (added 2026-06-26)
# ============================================================================
$__regPath = @(
    [Environment]::GetEnvironmentVariable('Path', 'Machine')
    [Environment]::GetEnvironmentVariable('Path', 'User')
) -join ';'
$__seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$env:Path = (@(
    foreach ($__p in (($__regPath + ';' + $env:Path) -split ';')) {
        if ($__p -and $__seen.Add($__p.TrimEnd('\'))) { $__p.TrimEnd('\') }
    }
) -join ';')
Remove-Variable __regPath, __seen, __p -ErrorAction SilentlyContinue

function jyepe {
    Set-Location "C:\Users\jyepe"
}

function desktop {
    Set-Location "C:\Users\jyepe\Desktop"
}

function docs {
    Set-Location "C:\Users\jyepe\Documents"
}

# --- Repo navigation shortcuts (C:\Users\jyepe\source\repos) ---
function ecare {
    Set-Location "C:\Users\jyepe\source\repos\eCare"
}

function ecare360 {
    Set-Location "C:\Users\jyepe\source\repos\eCare360"
}

function ecaredbup {
    Set-Location "C:\Users\jyepe\source\repos\eCareDbUp"
}

function ilsapi {
    Set-Location "C:\Users\jyepe\source\repos\ILS.API"
}

function ilsidp {
    Set-Location "C:\Users\jyepe\source\repos\ILS.IDP"
}

# --- Open the .sln in the current directory (regardless of its name) ---
function sln {
    $f = Get-ChildItem -Filter *.sln -File | Select-Object -First 1
    if ($f) { Invoke-Item $f.FullName }
    else    { Write-Warning "No .sln found in $PWD" }
}

# ============================================================================
#  Shell customization — Oh My Posh + PSReadLine + Terminal-Icons
#  (added 2026-06-24)
# ============================================================================

# --- Oh My Posh: themed prompt (git branch, path, exit status) ---
# Installed via Chocolatey, which puts it under "Program Files (x86)" rather
# than the winget/manual-install location under LOCALAPPDATA. Check both so
# this keeps working regardless of install method. (updated 2026-07-13)
$env:POSH_THEMES_PATH = "C:\Program Files (x86)\oh-my-posh\themes"
$ompExe = "C:\Program Files (x86)\oh-my-posh\bin\oh-my-posh.exe"
if (-not (Test-Path $ompExe)) {
    $ompExe = "$env:LOCALAPPDATA\Programs\oh-my-posh\bin\oh-my-posh.exe"
    $env:POSH_THEMES_PATH = "$env:LOCALAPPDATA\Programs\oh-my-posh\themes"
}
if (Test-Path $ompExe) {
    & $ompExe init pwsh --config "$env:POSH_THEMES_PATH\tokyonight_storm.omp.json" | Invoke-Expression
}

# --- PSReadLine: predictive autosuggestions + smart completion ---
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Key Tab       -Function MenuComplete
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# --- Terminal-Icons: file/folder icons in directory listings ---
Import-Module Terminal-Icons -ErrorAction SilentlyContinue

# --- Make `ls` show hidden/system items too ---
# Overrides the built-in `ls` alias (Get-ChildItem) so hidden and system
# files/folders are always listed. Forwards all args, so `ls C:\path`,
# `ls *.log`, etc. still work.
Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
function ls { Get-ChildItem -Force @args }

# --- Make `rm` recursive + forced by default ---
# Overrides the built-in `rm` alias (Remove-Item) so `rm <folder>` deletes the
# folder and its contents without prompting (and removes hidden/read-only items).
# Forwards all args. NOTE: permanent delete (no Recycle Bin) — be deliberate.
Remove-Item Alias:rm -Force -ErrorAction SilentlyContinue
function rm { Remove-Item -Recurse -Force @args }

# --- lst: depth-limited tree view ---
# `lst [path] [depth]` prints an indented tree, default 2 levels deep. Native
# `tree /F` can't limit depth; `ls -Recurse` isn't a tree — this does both.
# Includes hidden/system items (-Force), like `ls`. Uses Terminal-Icons glyphs +
# per-filetype colors (via Format-TerminalIcons) when available, else cyan/gray.
#   lst            # current dir, 2 deep      lst .\src 3   # src, 3 deep
function lst {
    param([string]$Path = '.', [int]$Depth = 2)
    $useIcons = [bool](Get-Command Format-TerminalIcons -ErrorAction SilentlyContinue)
    function Show-Tree($dir, $prefix, $level, $max) {
        if ($level -gt $max) { return }
        $items = Get-ChildItem -LiteralPath $dir -Force -ErrorAction SilentlyContinue |
                 Sort-Object @{ E = { -not $_.PSIsContainer } }, Name
        for ($i = 0; $i -lt $items.Count; $i++) {
            $item = $items[$i]
            $last = ($i -eq $items.Count - 1)
            Write-Host ($prefix + ($last ? '└── ' : '├── ')) -NoNewline
            if ($useIcons) { Write-Host (Format-TerminalIcons $item) }
            else { Write-Host $item.Name -ForegroundColor ($item.PSIsContainer ? 'Cyan' : 'Gray') }
            if ($item.PSIsContainer) {
                Show-Tree $item.FullName ($prefix + ($last ? '    ' : '│   ')) ($level + 1) $max
            }
        }
    }
    $root = (Resolve-Path $Path).Path
    Write-Host $root -ForegroundColor Green
    Show-Tree $root '' 1 $Depth
}

# --- ff: find files/folders by partial name in all subdirectories ---
# `ff <term>` recursively finds items whose name contains <term> (wildcards
# added automatically -> *term*). Searches from the current dir, or pass -Path.
# Includes hidden/system items (-Force); skips dirs it can't read. Matches both
# files and folders. E.g. `ff config`, `ff .json`, `ff glaze -Path .\wiki`.
# Prints one compact line per hit: dim relative path + Terminal-Icons name, with
# a match count. Use -PassThru to get the raw file objects instead (for piping).
function ff {
    param([Parameter(Mandatory)][string]$Pattern, [string]$Path = '.', [switch]$PassThru)
    $base = (Resolve-Path $Path).Path
    $hits = @(Get-ChildItem -Path $Path -Recurse -Force -Filter "*$Pattern*" -ErrorAction SilentlyContinue)
    if ($PassThru) { return $hits }
    $useIcons = [bool](Get-Command Format-TerminalIcons -ErrorAction SilentlyContinue)
    foreach ($h in $hits) {
        $dir = Split-Path ($h.FullName.Substring($base.Length).TrimStart('\')) -Parent
        if ($dir) { Write-Host ($dir + '\') -NoNewline -ForegroundColor Gray }
        if ($useIcons) { Write-Host (Format-TerminalIcons $h) }
        else { Write-Host $h.Name -ForegroundColor ($h.PSIsContainer ? 'Cyan' : 'Gray') }
    }
    $n = $hits.Count
    Write-Host ("{0} match{1}" -f $n, ($(if ($n -eq 1) { '' } else { 'es' }))) -ForegroundColor Green
}

# --- glow: wrap the glow.exe markdown viewer, adding an `open` finder ---
# `glow open <name>` recursively searches (via ff) for FILES matching *name* and
# opens the match in glow. 0 matches -> warn. 1 -> open it. Several -> pick one
# (fzf picker if available, else a numbered menu). Scope with -Path (name first):
#   glow open readme            glow open .json           glow open notes -Path .\wiki
# Anything that isn't the `open` subcommand is forwarded straight to glow.exe, so
# normal `glow file.md`, `glow .`, `glow <url>` etc. keep working unchanged.
# (Calling glow.exe by its extension bypasses this function and hits the real exe.)
function glow {
    if ($args.Count -ge 1 -and $args[0] -eq 'open') {
        $rest = if ($args.Count -gt 1) { @($args[1..($args.Count - 1)]) } else { @() }
        # First non-switch token is the search term; the rest (e.g. -Path .\dir)
        # is forwarded to ff. Pass the name first, before any -Path.
        $term = $null; $pass = @()
        foreach ($a in $rest) { if (-not $term -and $a -notmatch '^-') { $term = $a } else { $pass += $a } }
        if (-not $term) { Write-Warning 'Usage: glow open <name> [-Path <dir>]'; return }

        $hits = @(ff $term -PassThru @pass | Where-Object { -not $_.PSIsContainer })
        if ($hits.Count -eq 0) { Write-Warning "glow open: no file matching '*$term*'"; return }

        if ($hits.Count -eq 1) {
            $target = $hits[0].FullName
        } elseif (Get-Command fzf -ErrorAction SilentlyContinue) {
            $target = $hits.FullName | fzf --prompt 'glow open> ' --height 40% --reverse
            if (-not $target) { return }                       # Esc / nothing picked
        } else {
            Write-Host "Multiple matches for '$term':" -ForegroundColor Cyan
            for ($i = 0; $i -lt $hits.Count; $i++) {
                Write-Host ("{0,3}  {1}" -f ($i + 1), $hits[$i].FullName)
            }
            $sel = Read-Host 'Select # (Enter to cancel)'
            if (-not $sel) { return }
            $idx = ($sel -as [int]) - 1
            if ($null -eq ($sel -as [int]) -or $idx -lt 0 -or $idx -ge $hits.Count) {
                Write-Warning 'glow open: invalid selection'; return
            }
            $target = $hits[$idx].FullName
        }
        glow.exe $target
    } else {
        glow.exe @args
    }
}

# --- Auto-list directory contents after every directory change ---
# Wraps Set-Location so `cd`, `sl`, and the jyepe/desktop/docs shortcuts
# all show the folder's contents automatically (no extra ls/dir needed).
function Set-Location {
    Microsoft.PowerShell.Management\Set-Location @args
    if ($?) { Get-ChildItem -Force }
}

# --- Git aliases (names chosen to avoid shadowing built-in aliases) ---
function gs   { git status -sb @args }
function ga   { git add @args }
function gaa  { git add --all @args }
function gcom { git commit @args }
function gca  { git commit -a -m @args }
function gco  {
    # Bare `gco` opens an fzf picker of local branches (most-recent-first,
    # like gb), with a live preview of each branch's recent commits; Enter
    # checks it out, Esc cancels. `gco <branch>` / `gco -- <file>` etc. behave
    # exactly as `git checkout` did before. See wiki [[powershell-profile]].
    if ($args.Count -eq 0) {
        $branch = git branch --sort=-committerdate --format='%(refname:short)' |
            fzf --height 40% --reverse --ansi --prompt 'checkout> ' `
                --preview 'git log --oneline --color=always -20 {}'
        if ($branch) { git checkout $branch }
    } else {
        git checkout @args
    }
}
function gsw  { git switch -c @args }   # create & switch to a new branch (git switch -c)
# gb/gba use a hash-first --format instead of `git branch -vv`, whose default
# pads the branch column to the longest name (90+ chars here) and shoves the
# subject far right / wraps. Hash-first keeps rows readable at any width.
# Sorted most-recent-first. Cols: marker hash branch upstream[ahead/behind] subject.
$GitBranchFormat = '%(HEAD) %(color:yellow)%(objectname:short)%(color:reset) %(color:cyan)%(refname:short)%(color:reset) %(color:blue)%(upstream:short)%(color:reset)%(color:red)%(upstream:track)%(color:reset) %(contents:subject)'
function gb   { git branch    --sort=-committerdate "--format=$GitBranchFormat" @args }
function gba  { git branch -a --sort=-committerdate "--format=$GitBranchFormat" @args }
function gpl  { git pull @args }
function gpu  { git push @args }
function gf   { git fetch @args }
function gd {
    # Bare `gd` opens an fzf picker of files changed in the working tree
    # (unstaged; falls back to staged if none), with a live diff preview.
    # Tab to multi-select, Enter to confirm, Esc cancels. Selected file(s)'
    # diff is then shown through bat with diff syntax highlighting (colors,
    # no line numbers/gutter -- those don't apply to diff output).
    # `gd <args>` (e.g. `gd HEAD~1`, `gd --staged`, `gd -- file.txt`) behaves
    # exactly as `git diff` did before. See wiki [[powershell-profile]].
    if ($args.Count -eq 0) {
        $files = git diff --name-only
        if (-not $files) { $files = git diff --staged --name-only }
        if (-not $files) { Write-Host 'gd: no changes to diff.' -ForegroundColor Yellow; return }

        $selected = $files | fzf --multi --height 40% --reverse --prompt 'diff> ' `
            --preview 'git diff --color=always -- {}' --preview-window=right:60%
        if (-not $selected) { return }

        if (Get-Command bat -ErrorAction SilentlyContinue) {
            git diff --no-color -- $selected | bat --language=diff --paging=always
        } else {
            git diff -- $selected
        }
    } else {
        git diff @args
    }
}
function gr   { git restore @args }     # discard uncommitted changes: gr <file> (permanent!)
function glg  { git log --oneline --graph --decorate --all @args }
function gst  { git stash @args }
function gcl  { git clone @args }

# --- gws: show which apps are open in which GlazeWM workspace ---
# Queries the running GlazeWM (the `glazewm` on PATH is the cli wrapper) and
# prints each workspace with its windows ([process] title). Requires GlazeWM
# running; see the Vault44 wiki [[glazewm]] page.
function gws {
    $cli = if (Get-Command glazewm -ErrorAction SilentlyContinue) { 'glazewm' }
           else { 'C:\Program Files\glzr.io\GlazeWM\cli\glazewm.exe' }
    try { $json = & $cli query workspaces 2>$null | ConvertFrom-Json }
    catch { Write-Warning 'gws: could not query GlazeWM (is it running?)'; return }
    if (-not $json.success) { Write-Warning 'gws: query failed'; return }

    function Get-GwsWindows($node) {
        $acc = @()
        foreach ($c in $node.children) {
            if ($c.type -eq 'window') { $acc += $c }
            elseif ($c.children)      { $acc += Get-GwsWindows $c }
        }
        $acc
    }

    foreach ($ws in ($json.data.workspaces | Sort-Object name)) {
        $wins  = @(Get-GwsWindows $ws)
        $label = if ($ws.displayName) { "$($ws.name) ($($ws.displayName))" } else { "$($ws.name)" }
        Write-Host ''
        Write-Host ("WS $label - $($wins.Count) window(s)") -ForegroundColor Cyan
        if ($wins.Count -eq 0) { Write-Host '    (empty)' -ForegroundColor DarkGray }
        else { foreach ($w in $wins) { Write-Host ("    [{0}] {1}" -f $w.processName, $w.title) } }
    }
}

# ============================================================================
#  zoxide — smarter cd
#    `cd <partial>`  jumps to the most frecent matching dir (zoxide's `z`)
#    `cdi <partial>` opens the interactive fzf picker (zoxide's `zi`)
#    plain `cd <path>`, `cd ..`, `cd -`, and `cd` (home) all still work
#  Uses --no-cmd so we can define cd/cdi ourselves and keep the auto-listing
#  (zoxide's internal Set-Location bypasses the wrapper above, so we list here).
#  (added 2026-06-25)
# ============================================================================
# Ensure manually-installed CLI tools (zoxide, fzf) in ~\bin are on PATH, even
# if this shell inherited a stale environment from a long-running parent.
if ((Test-Path "$HOME\bin") -and (($env:Path -split ';') -notcontains "$HOME\bin")) {
    $env:Path += ";$HOME\bin"
}
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell --no-cmd | Out-String) })
    Remove-Item Alias:cd  -Force -ErrorAction SilentlyContinue
    Remove-Item Alias:cdi -Force -ErrorAction SilentlyContinue
    # List the destination only when the directory actually changed, so a
    # "no match found" query just shows the warning (no stray listing).
    function global:cd  { $p = $PWD.Path; __zoxide_z  @args; if ($PWD.Path -ne $p) { Get-ChildItem -Force } }
    function global:cdi { $p = $PWD.Path; __zoxide_zi @args; if ($PWD.Path -ne $p) { Get-ChildItem -Force } }
}

# ============================================================================
#  bat — cat clone with syntax highlighting + git integration
#    `bat`   -> highlighted, paged view (native cat/Get-Content untouched)
#    `catp`  -> bat --paging=never (highlighted, no pager, like plain cat)
#    `batp`  -> bat --plain (no line numbers/git gutter, good for copying text)
#  Paging: bat looks for `less` on PATH, which Windows doesn`t ship. Git for
#  Windows bundles one, so point BAT_PAGER straight at it (works even though
#  that folder isn`t on PATH). -R keeps ANSI colors, -F exits if content fits
#  one screen (no need to press q on short files).
#  fzf preview: any fzf picker that sets --preview can shell out to bat for
#  syntax-highlighted, line-numbered previews (see `gco`/`cdi`/`glow open`).
#  (added 2026-07-09)
# ============================================================================
$__gitLess = "$env:LOCALAPPDATA\Programs\Git\usr\bin\less.exe"
if (-not (Get-Command less -ErrorAction SilentlyContinue) -and (Test-Path $__gitLess)) {
    $env:BAT_PAGER = "`"$__gitLess`" -RF"
}
Remove-Variable __gitLess -ErrorAction SilentlyContinue

if (Get-Command bat -ErrorAction SilentlyContinue) {
    function catp { bat --paging=never @args }
    function batp { bat --plain @args }

    # Shared fzf preview command: numbered, colored, capped at 500 lines for speed.
    $env:FZF_DEFAULT_OPTS = "--preview `"bat --color=always --style=numbers --line-range=:500 {}`""
}
