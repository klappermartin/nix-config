{
  imports = [
    ../../darwin
    ../../modules/darwin/homebrew/personal.nix
    ../../modules/darwin/services/tailscale.nix
  ];

  # Existing M2 MacBook Pro. Keep this output name for existing rebuild commands.
  _module.args.username = "martin";
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 5;

  # The machine's SSH signing key (no default; every host declares its own).
  home-manager.users.martin.workstation.ssh.keyFile = ".ssh/id_ed25519";
  home-manager.users.martin.imports = [ ./home.nix ];
}
