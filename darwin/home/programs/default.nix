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

    herdr = {
      enable = true;
      # Preserve in-app settings; these declared defaults win on rebuild.
      mutableSettings = true;
      settings = {
        onboarding = false;
        theme = {
          name = "terminal";
          auto_switch = false;
        };
        terminal = {
          default_shell = "${pkgs.zsh}/bin/zsh";
          shell_mode = "auto";
          new_cwd = "follow";
        };
        update.version_check = false;
        ui = {
          status_indicators = "symbols";
          sound.enabled = false;
          agent_panel_sort = "priority";
          toast.delivery = "terminal";
          prompt_new_tab_name = false;
          show_agent_labels_on_pane_borders = true;
        };
        keys.command = [
          {
            key = "prefix+f";
            type = "plugin_action";
            command = "persiyanov.reviewr.toggle";
            description = "toggle reviewr";
          }
        ];
      };
    };

    lsd = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      settings = {
        classic = false;
        layout = "grid";
        blocks = [
          "permission"
          "user"
          "size"
          "date"
          "name"
        ];
        color = {
          when = "auto";
          theme = "default";
        };
        icons = {
          when = "auto";
          theme = "fancy";
          separator = "  ";
        };
        size = "short";
        date = "relative";
        permission = "rwx";
        sorting = {
          column = "name";
          dir-grouping = "first";
        };
        hyperlink = "auto";
        symlink-arrow = "→";
        # Avoid recursively walking large repositories just to list a directory.
        total-size = false;
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
