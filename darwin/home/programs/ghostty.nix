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
      # keep in sync with tmux historyLimit; the byte cap (default 50 MB) would
      # otherwise cut this to ~20k-40k lines, so raise it as a safety cap only
      scrollback-limit-lines = 50000;
      scrollback-limit-bytes = 200000000;
    };
  };
}
