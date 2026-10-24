# nix-config

nix-config for development machine (currently only aarch64-darwin / Apple Silicon)

## Features

- Complete system configuration via nix-darwin
- User environment management with home-manager
- Window management with yabai and skhd
- Custom status bar with sketchybar
- Application installation through both Nix and Homebrew
- Extensive terminal setup with zsh, tmux, and kitty

## Setup

### Prerequisites

1. Install Nix (multi-user mode)

```bash
curl -L https://nixos.org/nix/install | sh -s -- --daemon
```

2. Enable flakes

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

3. Clone the configuration

```bash
git clone git@github.com:klappermartin/nix-config.git ~/nix
cd ~/nix
```


### Initial Setup

1. Run darwin-rebuild for the first time

```bash
sudo nix run github:nix-darwin/nix-darwin/master#darwin-rebuild -- switch --flake .
```

2. After the first switch, you can use:
```bash
sudo darwin-rebuild switch --flake .
```

## Configuration Structure

- `flake.nix` - Main entry point and input definitions
- `darwin/system/configuration.nix` - System-wide macOS settings
- `darwin/system/homebrew.nix` - Homebrew (nix-homebrew taps + casks) and Rosetta
- `darwin/system/home-manager.nix` - home-manager wiring
- `darwin/system/overlays.nix` - nixpkgs overlays (NUR, package pins)
- `darwin/home/home.nix` - User-specific configurations
- `darwin/home/sketchybar/` - Status bar Lua configuration

## Included Software

### Core Tools
- Firefox (with extension and configuration)
- VSCodium (with extensions)
- Kitty terminal
- Tmux
- Git setup


### Window Management
- Yabai for tiling window management
- Skhd for keyboard shortcuts
- JankyBorders for window borders
- Sketchybar for a customizable status bar

config for this is very much taken from https://github.com/FelixKratz - amazing repos!

### Homebrew Applications
- whatever is not available on nixpkgs for darwin (or has macOS such as screen share permissions)
- cleanup is `zap`, which deletes app data of casks removed from the list, so apps
  with local state worth keeping (chat history, mail) are installed from nixpkgs

## Utilities

### oss-ref — OSS Reference Manager

`oss-ref` clones versioned OSS repositories into a shared references root and symlinks them into consumer projects. A weekly launchd agent prunes orphaned references automatically. See [`skills/oss-reference/SKILL.md`](skills/oss-reference/SKILL.md) for full documentation.

Key environment variables: `OSS_REFERENCES_ROOT` (default: `~/code/others/oss-references`) and `OSS_REFERENCES_CONSUMER_ROOTS` (default: `~/code`).

## TODO List

1. **Security**
   - [ ] Set up sops-nix now that there is nix-darwin support
   - [ ] Configure Kagi session token for Firefox

2. **Development Setup**
   - [ ] Move dev-related packages into a dedicated module

3. **Sketchybar Configuration**
   - [ ] Fetch/copy examples from sketchybar config
   - [ ] Complete sketchybar implementation

4. **Extensions & Settings**
   - [ ] Persist extension configurations separately
   - [ ] Configure browser extension settings

5. **Shell Configuration**
   - [ ] Research / Set up aliases for Kagi search lenses

6. **General**
    - [ ] Setup non-darwin config before moving machine

## Usage Notes

- SSH: Home Manager manages `~/.ssh/config`; add local hosts and identities in
  `~/.ssh/config.d/*.conf` without rebuilding. For example:

  ```sshconfig
  Host my-server
    HostName server.example.com
    User martin
    IdentityFile ~/.ssh/id_ed25519_server
    IdentitiesOnly yes
  ```

  Local files are read before the managed GitHub configuration and the Colima
  include. Use host-specific blocks; `IdentityFile` entries accumulate, so use
  distinct host aliases for different identities. Keep keys outside the repo.
- fzf history (Ctrl-R): recent matches first; Ctrl-R toggles relevance sorting,
  Ctrl-Space toggles the full-command preview, Ctrl-Y copies, and Enter inserts
  the command for editing.
- btop uses the terminal's ANSI colors and background. In-app settings changes
  last for the session; persistent settings live in `programs/default.nix`.
- Herdr settings stay writable. Rebuilds merge the declared settings into
  `~/.config/herdr/config.toml`; declared values (including the command-keybinding
  array) win. Removing a declaration does not remove its saved value.
- Reviewr: `Ctrl-B`, then `f` toggles the review pane. Select lines with `v`,
  add comments with `c`, and send them to the agent with `s`. The plugin is
  installed separately from the Nix configuration:

  ```sh
  herdr plugin install persiyanov/herdr-reviewr --ref v0.48.0
  ```

  This pins the plugin to that release; install with a newer `--ref` to upgrade.
- `ls`, `ll`, `la`, `lla`, `lt`, and `llt` use lsd: automatic colors and Nerd Font
  icons, directories first, compact sizes, and relative dates. `ll` shows
  permissions, owner, size, date, and name; `lt` shows a tree. Use `/bin/ls` for
  the macOS implementation. Colors, icons, and hyperlinks are automatic.

- Home Manager keeps two backups of conflicting local files: `.backup` (newest)
  and `.backup.2` (previous). A new conflict replaces the oldest backup, then
  installs the declared configuration. Normal updates to managed symlinks do not
  create backups. Older manually named backups are left untouched.
- Window management: Use left alt + keys (or ralt) for navigation and window operations
- Status bar: Toggle with shift + left alt + space
