{
  pkgs,
  ...
}:
{
  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty-bin;
    enableZshIntegration = true;
    settings = {
      theme = "TokyoNight";
      font-family = "JetBrainsMono Nerd Font";
      font-size = 11;
      font-feature = [
        "-liga"
        "-calt"
        "-dlig"
      ];
      macos-titlebar-style = "hidden";
      window-padding-x = 4;
      window-padding-y = 4;
    };
  };
}
