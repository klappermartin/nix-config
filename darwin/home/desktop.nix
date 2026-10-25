{ lib, ... }:
{
  # Host overrides live in home-manager.users.<user>.workstation.desktop.
  options.workstation.desktop = {
    networkInterface = lib.mkOption {
      type = lib.types.strMatching "[a-zA-Z][a-zA-Z0-9]*";
      default = "en0";
      description = "Interface used by the network and Wi-Fi status items.";
    };
    spaceKeysPerDisplay = lib.mkOption {
      type = lib.types.ints.between 1 9;
      default = 4;
      description = "Number-key hotkeys for spaces on the focused display.";
    };
    spaceCount = lib.mkOption {
      type = lib.types.ints.positive;
      default = 10;
      description = "Total global space slots shown by Sketchybar, across all displays.";
    };
  };
}
