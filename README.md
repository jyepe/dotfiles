# dotfiles

Personal dotfiles for Windows — WezTerm + Neovim (LazyVim) + Starship prompt.

## Repo layout

```
dotfiles/
  nvim/                     # Neovim config (LazyVim distribution + customizations)
  wezterm/.wezterm.lua      # WezTerm config
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
