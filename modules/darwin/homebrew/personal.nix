{ config, ... }:
{
  imports = [
    ./base.nix
    ./inventory/productivity.nix
    ./inventory/entertainment.nix
    ./inventory/gaming.nix
  ];

  homebrew = {
    enable = true;
    taps = builtins.attrNames config.nix-homebrew.taps;
    brews = [ ];
    caskArgs.require_sha = true;
    masApps = { };
    onActivation = {
      autoUpdate = false;
      # This is deliberately not zap: manual installations must survive.
      cleanup = "none";
      upgrade = true;
    };
  };
}
