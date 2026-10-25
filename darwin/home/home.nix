{
  imports = [
    ./desktop.nix
    ./packages.nix
    ./programs
    ./services
  ];

  # username and homeDirectory are inherited from users.users via the home-manager darwin module
  home.stateVersion = "25.05";

  targets.darwin = {
    linkApps.enable = false;
    copyApps.enable = true;
  };
}
