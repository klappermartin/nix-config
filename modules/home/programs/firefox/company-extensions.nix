{ pkgs, ... }:
{
  programs.firefox.profiles.dev-edition-default.extensions.packages = import ./extensions.nix {
    inherit pkgs;
  };
}
