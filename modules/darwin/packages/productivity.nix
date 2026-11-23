{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    bitwarden-cli
    bitwarden-desktop
    (firefox.override {
      # Let regular Firefox manage its own profiles, separate from Developer Edition.
      appDataDir = "${config.home.homeDirectory}/Library/Application Support/org.nixos.firefox";
    })
    gdu
    handy
    hyperfine
    obsidian
    raycast
  ];
}
