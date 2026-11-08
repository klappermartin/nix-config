{
  nix.settings.experimental-features = "nix-command flakes";
  # Merged with the default cache.nixos.org substituter.
  nix.settings.substituters = [ "https://devenv.cachix.org" ];
  nix.settings.trusted-public-keys = [
    "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
  ];
  nix.optimise.automatic = true;
}
