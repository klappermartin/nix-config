{
  config,
  inputs,
  username,
  ...
}:
{
  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = username;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
    mutableTaps = false;
  };

  # nix-homebrew only warns when Rosetta is missing; extraActivation runs before
  # the homebrew activation step, so casks that need Rosetta work on a fresh machine.
  system.activationScripts.extraActivation.text = ''
    if ! /usr/bin/pgrep -q oahd; then
      echo "installing Rosetta..." >&2
      /usr/sbin/softwareupdate --install-rosetta --agree-to-license
    fi
  '';

  homebrew = {
    enable = true;
    # use taps declared by nix-homebrew
    taps = builtins.attrNames config.nix-homebrew.taps;
    brews = [ ];
    caskArgs = {
      require_sha = true;
    };
    # zap removes app data of casks dropped from this list; apps with local
    # state worth keeping (chat history, mail) belong in nixpkgs instead
    casks =
      let
        cask = name: {
          inherit name;
          greedy = true;
        };
        # casks that don't publish a sha256
        unverifiedCask = name: cask name // { args.require_sha = false; };
      in
      map cask [
        "balenaetcher"
        "karabiner-elements"
        "linear"
      ]
      ++ map unverifiedCask [
        "font-sf-mono"
        "font-sf-pro"
        "nvidia-geforce-now"
        "spotify"
      ];

    masApps = { };
    onActivation = {
      autoUpdate = false;
      # TODO: back to "zap" after one switch; "uninstall" keeps the data of the
      # slack/whatsapp/thunderbird casks that moved to nixpkgs
      cleanup = "uninstall";
      # taps are pinned via flake.lock, so this only upgrades casks after `nix flake update`
      upgrade = true;
    };
  };
}
