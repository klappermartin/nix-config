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
    # Homebrew is exclusively declarative: zap removes ALL unlisted packages,
    # including manual installs, and applies casks' associated-data cleanup rules.
    # Prefer nixpkgs; Homebrew is only for macOS packaging/availability exceptions.
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
      cleanup = "zap";
      # Recipes are lock-pinned. Unchecked vendor downloads and app self-updates
      # can still change independently; greedy casks may upgrade on any rebuild.
      upgrade = true;
    };
  };
}
