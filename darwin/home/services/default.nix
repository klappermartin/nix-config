{
  pkgs,
  ...
}:
{
  imports = [
    ./jankyborders.nix
    ./oss-references-pruner.nix
    ./sketchybar.nix
    ./skhd.nix
  ];

  services = {
    gpg-agent = {
      enable = true;
      enableZshIntegration = true;
      defaultCacheTtl = 21600; # 6 hours
      maxCacheTtl = 86400; # 1 day
      pinentry.package = pkgs.pinentry_mac;
    };

    oss-references-pruner = {
      enable = true;
    };
  };
}
