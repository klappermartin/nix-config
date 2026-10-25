{ inputs, ... }:
{
  imports = [
    ./system/configuration.nix
    ./system/overlays.nix
    inputs.nix-homebrew.darwinModules.nix-homebrew
    ./system/homebrew.nix
    inputs.home-manager.darwinModules.home-manager
    ./system/home-manager.nix
  ];
}
