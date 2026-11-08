{ pkgs, ... }:
{
  home.packages = with pkgs; [
    osu-lazer-bin
    # Temporary workaround for a Darwin bash 5.3 wrapQtAppsHook segfault.
    (prismlauncher.overrideAttrs { LANG = "C"; })
  ];
}
