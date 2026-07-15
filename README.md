# dotfiles

Personal dotfiles for Windows — WezTerm + Neovim (LazyVim) + Starship prompt.

## Repo layout

```text
dotfiles/
  nvim/                     # Neovim config (LazyVim distribution + customizations)
  wezterm/                   # Shared modular WezTerm configuration
    .wezterm.lua             # Root configuration loader
    workspaces.lua           # Workspace startup and picker behavior
    workspace_config.lua     # Local definition loading and validation
    workspaces.local.example.lua
    tab_bar.lua              # Workspace status and tab styling
  starship/starship.toml   # Starship prompt config
  bootstrap.ps1             # symlinks everything into place
```

## Setup on a new PC

### 1. Install prerequisites

```powershell
winget install wez.wezterm
winget install Neovim.Neovim
winget install Microsoft.PowerShell
winget install starship
# A Nerd Font — required for WezTerm + LazyVim icons
winget install --id DEVCOM.JetBrainsMonoNerdFont
# Or install CaskaydiaCove Nerd Font manually from
# https://www.nerdfonts.com/font-downloads

# LazyVim dependencies
winget install BurntSushi.ripgrep.MSVC
winget install Git.Git
# A C compiler (for nvim-treesitter) — pick one:
winget install MartinStorsjo.LLVM-Mingw
# or: winget install Kitware.CMake

# PowerShell modules referenced in the prompt
Install-Module Terminal-Icons -Scope CurrentUser -Force
```

### 2. Clone this repo

```powershell
git clone git@github.com:jyepe/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 3. Run the bootstrap script

Symlinking on Windows needs either admin rights or Developer Mode enabled
(Settings → Privacy & Security → For developers → Developer Mode = On).

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\bootstrap.ps1
```

This symlinks:

- `~/dotfiles/nvim`             → `%LOCALAPPDATA%\nvim`
- `~/dotfiles/wezterm/.wezterm.lua` → `~/.wezterm.lua`
- `~/dotfiles/starship/starship.toml` → `~/.config/starship.toml`

Existing files at those targets are backed up to `*.bak` before linking.

### 4. First launch

- **WezTerm**: open the app — config loads automatically.
- **Neovim**: run `nvim` once; LazyVim auto-installs all plugins pinned in
  `nvim/lazy-lock.json`. Restart after the install completes.
- **Starship**: ensure your PowerShell profile invokes Starship. If not, add
  `Invoke-Expression (&starship init powershell)` to your PowerShell profile.

### Configure machine-local WezTerm workspaces

Workspaces are optional and machine-specific. WezTerm always starts with a
`home` workspace rooted at your user directory.

To add workspaces on a PC, create:

`~/.config/wezterm/workspaces.local.lua`

Use `wezterm/workspaces.local.example.lua` as the template:

```lua
return {
  home = {
    { name = "dotfiles", cwd = "C:/Users/your-name/dotfiles" },
    { name = "personal", cwd = "C:/Users/your-name/Documents/personal" },
  },
  work = {
    { name = "client", cwd = "D:/Work/client" },
    { name = "docs", cwd = "D:/Work/docs" },
  },
}
```

Use forward slashes in Windows paths. The local file is outside this repository,
so each PC can use different paths. WezTerm asks which profile to use when a
window is created; the selected profile controls the workspace selector.

Workspace and tab shortcuts:

- `Ctrl+Space`, then `Space`: search and switch workspaces in the active profile
- `Ctrl+Space`, then `c`: create/switch to a named workspace in the current directory
- `Ctrl+Space`, then `m`: change the active workspace profile
- `Ctrl+Space`, then `t`: new tab in the active workspace
- `Ctrl+Space`, then `w`: close current tab
- `Ctrl+Space`, then `1` through `8`: jump to a tab
- `Ctrl+Space`, then `Tab` / `Shift+Tab`: next / previous tab

Configured workspaces are persisted on disk in the local file and created only
when selected. Selecting one whose directory does not exist leaves the current
workspace active and shows a notification.

## Updating

Edit files in the repo, then commit and push. Symlinks mean the live configs
track the repo working tree — no copy step needed.

```powershell
cd ~/dotfiles
git add -A
git commit -m "tweak: ..."
git push
```

To pull on the other PC:

```powershell
cd ~/dotfiles
git pull
# Restart WezTerm/nvim to pick up changes.
```
