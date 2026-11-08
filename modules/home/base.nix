{
  imports = [
    ./ssh-options.nix
    ./programs/git
    ./programs/firefox/base.nix
  ];

  # This state version is user-profile compatibility data, not Darwin-specific.
  home.stateVersion = "25.05";
}
