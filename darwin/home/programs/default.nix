{
  pkgs,
  ...
}:
{
  imports = [
    ./firefox.nix
    ./git.nix
    ./ghostty.nix
    ./kitty.nix
    ./mpv.nix
    ./opencode
    ./oss-references.nix
    ./oxker.nix
    ./ssh.nix
    ./tmux.nix
    ./vscodium.nix
    ./zsh.nix
  ];

  programs = {
    home-manager.enable = true;

    bash.enable = true;

    btop = {
      enable = true;
      settings = {
        # TTY uses the terminal's ANSI palette; this also inherits its background.
        color_theme = "TTY";
        theme_background = false;
        force_tty = false;
        vim_keys = true;
        rounded_corners = true;
        graph_symbol = "braille";
        update_ms = 2000;
        background_update = false;
        shown_boxes = "net mem proc cpu";
        proc_sorting = "memory";
        proc_tree = false;
        proc_per_core = true;
        proc_mem_bytes = true;
        proc_info_smaps = false;
        show_disks = false;
        use_fstab = true;
        show_battery = true;
        # Home Manager owns this file; in-app changes last for the session.
        save_config_on_exit = false;
      };
    };

    chromium = {
      enable = true;
      package = pkgs.google-chrome;
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      historyWidget.options = [
        "--height=50%"
        "--layout=reverse"
        "--no-sort"
        ''--preview 'printf "%s\n" {2..}' ''
        "--preview-window=down:4:hidden:wrap"
        "--bind=ctrl-space:toggle-preview"
        ''--bind 'ctrl-y:execute-silent(printf "%s" {2..} | /usr/bin/pbcopy)+abort' ''
        "--header 'Ctrl-R: sort | Ctrl-Space: preview | Ctrl-Y: copy' "
      ];
    };

    herdr.enable = true;

    lsd = {
      enable = true;
      # Keep ls and its usual aliases on the system implementation, like remote
      # hosts. Explicit lsd calls use its ls-compatible, undecorated mode.
      enableBashIntegration = false;
      enableFishIntegration = false;
      enableZshIntegration = false;
      settings = {
        classic = true;
        size = "bytes";
        date = "date";
        sorting.dir-grouping = "none";
        hyperlink = "never";
      };
    };

    neovim = {
      enable = true;
      vimAlias = true;

      # explicit due to default change after current stateVersion
      withPython3 = false;
      withRuby = false;
    };

    oss-references = {
      enable = true;
    };

    pay-respects = {
      enable = true;
      enableZshIntegration = true;
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
