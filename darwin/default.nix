{ inputs, ... }:
{
  imports = [
    ../modules/common/nix.nix
    ../modules/darwin/system/configuration.nix
    ../modules/darwin/system/overlays.nix
    inputs.nix-homebrew.darwinModules.nix-homebrew
    inputs.home-manager.darwinModules.home-manager
    ../modules/darwin/system/home-manager.nix
  ];
}
