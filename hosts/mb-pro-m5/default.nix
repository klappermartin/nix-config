{
  imports = [
    ../../darwin
    ../../modules/darwin/homebrew/company.nix
  ];

  # M5 uses the same architecture and shared configuration as the M2.
  _module.args.username = "martin.klapper";
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 5;

  # The machine's SSH signing key (no default; every host declares its own).
  home-manager.users."martin.klapper".workstation.ssh.keyFile = ".ssh/id_ed25519";
  home-manager.users."martin.klapper".imports = [ ./home.nix ];
}
