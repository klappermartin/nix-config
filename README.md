# nix-config

nix-config for development machine (currently only aarch64-amd)

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
git clone https://github.com/yourusername/nix-config.git
cd nix-config
```


### Initial Setup

1. Run darwin-rebuild for the first time

```bash
sudo nix run github:LnL7/nix-darwin -- switch --flake .
```

2. After the first switch, you can use:
```bash
sudo darwin-rebuild switch --flake .
```

## Configuration Structure

- `flake.nix` - Main entry point and input definitions
- `darwin/system/configuration.nix` - System-wide macOS settings
- `darwin/home/home.nix` - User-specific configurations
- `darwin/home/sketchybar/` - Status bar configuration

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
   - [ ] Set up system PostgreSQL
   - [ ] evaluate overwriting system ssh explicitly

3. **Sketchybar Configuration**
   - [ ] Move Lua configuration to a better location
   - [ ] Fetch/copy examples from sketchybar config
   - [ ] Complete sketchybar implementation

4. **Extensions & Settings**
   - [ ] Persist extension configurations separately
   - [ ] Configure browser extension settings
   - [ ] Set up FZF history settings
   - [ ] don't use system python for anything - not good

5. **Shell Configuration**
   - [ ] Configure history options for ZSH
   - [ ] Research / Set up aliases for Kagi search lenses

6. **App Configurations**
   - [ ] Create custom colors and icons for LSD

7. **General**
    - [ ] Setup non-darwin config before moving machine

## Usage Notes

- Home Manager keeps two backups of conflicting local files: `.backup` (newest)
  and `.backup.2` (previous). A new conflict replaces the oldest backup, then
  installs the declared configuration. Normal updates to managed symlinks do not
  create backups. Older manually named backups are left untouched.
- Window management: Use left alt + keys (or ralt) for navigation and window operations
- Status bar: Toggle with shift + left alt + space
