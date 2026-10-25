{
  imports = [ ../../darwin ];

  # M5 uses the same architecture and shared configuration as the M2.
  _module.args.username = "martin";
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 5;
}
