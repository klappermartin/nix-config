{
  pkgs,
  ...
}:
{
  programs.tmux = {
    enable = true;

    baseIndex = 1;
    extraConfig = ''
      # Allow x-keys (like C-left to move by full word)
      set-option -g xterm-keys on

      # extended keys for navigation in interactive tui applications
      set -g extended-keys on
      set -g extended-keys-format csi-u

      # use vi key in copy mode
      setw -g mode-keys vi

      # bind alt + Arrowkeys to move by word in cli
      bind -n M-Left send-keys M-b
      bind -n M-Right send-keys M-f

      # bind pane-sync to ctrl + b + g
      bind C-g set-window-option synchronize-panes

      # Temporarily re-set the shell var for use with tmux sensibleOnTop
      # see: https://github.com/nix-community/home-manager/issues/5952
      set -gu default-command
      set -g default-shell "$SHELL"
    '';
    clock24 = true;
    mouse = true;
    plugins = with pkgs; [
      {
        plugin = tmuxPlugins.tokyo-night-tmux;
        extraConfig = ''
          # common macOS L; no unicode support
          set -g @tokyo-night-tmux_window_id_style none
        '';
      }
      tmuxPlugins.yank
    ];
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "tmux-256color";
    tmuxinator.enable = true;
  };
}
