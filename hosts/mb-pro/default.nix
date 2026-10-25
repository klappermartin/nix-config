{
  imports = [ ../../darwin ];

  # Existing M2 MacBook Pro. Keep this output name for existing rebuild commands.
  _module.args.username = "martin";
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 5;
}
