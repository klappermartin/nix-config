{ config, ... }:
{
  imports = [
    ./base.nix
    ./inventory/productivity.nix
    ./inventory/entertainment.nix
  ];

  homebrew = {
    enable = true;
    taps = builtins.attrNames config.nix-homebrew.taps;
    brews = [ ];
    caskArgs.require_sha = true;
    masApps = { };
    onActivation = {
      autoUpdate = false;
      # IT or manual installations may share this prefix.
      cleanup = "none";
      upgrade = true;
    };
  };
}
