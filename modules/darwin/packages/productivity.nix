{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    bitwarden-cli
    bitwarden-desktop
    gdu
    handy
    hyperfine
    obsidian
    raycast
  ];
}
