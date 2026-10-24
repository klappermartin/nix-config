{
  imports = [
    ./jankyborders.nix
    ./oss-references-pruner.nix
    ./sketchybar.nix
    ./skhd.nix
  ];

  services = {
    oss-references-pruner = {
      enable = true;
    };
  };
}
