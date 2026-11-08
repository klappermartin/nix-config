{ inputs, username, ... }:
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

  # nix-homebrew only warns when Rosetta is missing; this runs before Homebrew
  # activation so casks that need Rosetta work on a fresh machine.
  system.activationScripts.extraActivation.text = ''
    if ! /usr/bin/pgrep -q oahd; then
      echo "installing Rosetta..." >&2
      /usr/sbin/softwareupdate --install-rosetta --agree-to-license
    fi
  '';
}
