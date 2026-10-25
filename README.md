# nix-config

nix-config for Apple Silicon development machines, sharing one nix-darwin/Home Manager setup.

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

1. Run the darwin-rebuild supplied by this repository's locked Darwin input:

```bash
sudo nix run .#darwin-rebuild -- switch --flake .#mb-pro
```

2. After the first switch, you can use:
```bash
sudo darwin-rebuild switch --flake .#mb-pro
```

Use `mb-pro-m5` instead of `mb-pro` for the second MacBook. Explicit selectors
make installation independent of the machine's current LocalHostName.

### Second MacBook

Both M2 and M5 use `aarch64-darwin`; no hardware configuration or CPU-specific
package set is needed. `hosts/mb-pro-m5/default.nix` imports the same Darwin
configuration. Review its username before installation (currently `martin`).
Host identity/platform and future exceptions belong in `hosts/<name>/default.nix`.
For example, host-local Home Manager overrides can set:

```nix
home-manager.users.martin.workstation.desktop = {
  networkInterface = "en0";
  spaceKeysPerDisplay = 4; # focused-display hotkey indices
  spaceCount = 10;        # global status-bar slots across all displays
};
```

Install Command Line Tools for development; install full Xcode separately for
projects that require it. Grant Accessibility permissions to yabai/skhd and App
Management permissions when macOS requests them. Set up SSH/signing keys and
application logins separately; private keys and credentials are not in this repo.
Git signing currently expects `~/.ssh/id_ed25519.pub`; if using a new key, register
it with GitHub and update the allowed-signers declaration in `git.nix`.

Keep `system.stateVersion` and `home.stateVersion` as compatibility settings;
they do not select package releases. A future Intel or NixOS machine needs a
separate platform/OS composition, not an M-series chip-name conditional.

## Configuration Structure

- `flake.nix` - Main entry point and input definitions
- `hosts/mb-pro/`, `hosts/mb-pro-m5/` - Thin host identity/platform layers
- `darwin/default.nix` - Shared, explicit Darwin module composition
- `darwin/system/configuration.nix` - System-wide macOS settings
- `darwin/system/homebrew.nix` - Homebrew (nix-homebrew taps + casks) and Rosetta
- `darwin/system/home-manager.nix` - home-manager wiring
- `darwin/system/overlays.nix` - nixpkgs overlays (NUR, package pins)
- `darwin/home/home.nix` - User-specific configurations
- `darwin/home/desktop.nix` - Host-overridable desktop settings
- `darwin/home/sketchybar/` - Status bar Lua configuration
- `darwin/home/programs/opencode/` - OpenCode packages and global configuration
- `.opencode/opencode.json` - NixOS MCP connection for this repository

## Maintenance

```sh
nix flake check --no-build --no-write-lock-file
nix build --no-write-lock-file .#darwinConfigurations.mb-pro.system
sudo darwin-rebuild switch --flake .#mb-pro
```

For a source-only, offline evaluation (requires cached input sources):

```sh
nix eval --offline --no-write-lock-file \
  --option allow-import-from-derivation false --raw \
  .#darwinConfigurations.mb-pro.system.drvPath
```

Update inputs deliberately with `nix flake update`, review `flake.lock`, then run
the checks and build before switching. `nix flake check --no-build` does not build the complete
system. A build does not activate it or validate live permissions, hotkeys, or
application behavior. After a switch, check the managed skhd agent and exercise
window/space bindings and the status bar:

```sh
launchctl print "gui/$(id -u)/org.nix-community.home.skhd"
```

Home Manager owns skhd. Activation retires any legacy `com.koekeishiya.skhd`
registration and preserves its plist under
`~/.local/state/home-manager/retired-launchagents/`.

Keep a known-good Git revision/lock for recovery. To return to it, build and switch
that revision with the explicit host selector. Existing system generations are
also subject to the configured `nh` retention policy (five generations/seven days).
Nix rollback does not restore mutable application data or all Homebrew versions;
use normal data backups for those. `darwin-rebuild switch --dry-run` is not a
substitute for the non-activating evaluation/build commands above.

## Included Software

### Core Tools
- Firefox Developer Edition (with extensions and configuration)
- VSCodium (with extensions)
- Kitty terminal
- Tmux
- Git setup
- OpenCode V2 — see [configuration and project MCP setup](darwin/home/programs/opencode/README.md)
### Window Management
- Yabai for tiling window management
- Skhd for keyboard shortcuts
- JankyBorders for window borders
- Sketchybar for a customizable status bar

Window-management configuration draws from [FelixKratz's dotfiles](https://github.com/FelixKratz).

### Homebrew Applications
- Prefer nixpkgs; Homebrew handles macOS availability/packaging exceptions.
- Homebrew is exclusively declarative. `cleanup = "zap"` deliberately removes
  **all packages absent from the Brewfile**, including manual installations, and
  applies casks' associated-data cleanup rules. Declare additions in
  `darwin/system/homebrew.nix`.
- Tap recipes are pinned by `flake.lock`. Checksum-free vendor downloads,
  application self-updaters, and greedy casks can still change independently.

## Utilities

### oss-ref — OSS Reference Manager

`oss-ref` clones versioned OSS repositories into a shared references root and symlinks them into consumer projects. A weekly launchd agent reports orphaned references without deleting them. See [`skills/oss-reference/SKILL.md`](skills/oss-reference/SKILL.md) for full documentation.

Key environment variables: `OSS_REFERENCES_ROOT` (default: `~/code/others/oss-references`) and `OSS_REFERENCES_CONSUMER_ROOTS` (default: `~/code`).

All consumers must be discoverable under those roots. Missing roots, scan errors,
or unresolved symlink loops abort pruning; links into clone subdirectories protect
the whole clone. `add` reuses a verified repository/version and rejects destinations
outside the discovery scope. Preview with `oss-ref prune --dry-run`; delete with
`oss-ref prune --yes --min-age 7d`. After auditing existing consumers, automatic
deletion can be enabled with `services.oss-references-pruner.dryRun = false`.

## TODO List

1. **Security**
   - [ ] Set up sops-nix now that there is nix-darwin support
   - [ ] Configure Kagi session token for Firefox

2. **Development Setup**
   - [ ] Move dev-related packages into a dedicated module

3. **Extensions & Settings**
   - [ ] Persist extension configurations separately
   - [ ] Configure browser extension settings

4. **Shell Configuration**
   - [ ] Research / Set up aliases for Kagi search lenses

5. **General**
    - [ ] Add a separate OS composition if a NixOS host is introduced

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
  last for the session; persistent settings live in `darwin/home/programs/default.nix`.
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
