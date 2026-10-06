{
  pkgs,
  pkgs-stable,
  config,
  ...
}:
# TODO: Setup system postgres
# TODO: ? Overwrite default system ssh
{
  environment = {
    # symlink system packages to home manager zsh for completion access
    pathsToLink = [ "/share/zsh/" ];
    systemPackages = with pkgs; [
      darwin.xcode_26_5_Apple_silicon
      devenv
      # keepassxc
      nh
      vim
    ];
  };

  homebrew = {
    enable = true;
    # use taps declared by nix-homebrew
    taps = builtins.attrNames config.nix-homebrew.taps;
    brews = [
      "hasura-cli"
    ];
    caskArgs = {
      require_sha = true;
    };
    casks = [
      {
        name = "balenaetcher";
        greedy = true;
      }
      # included until https://github.com/bitwarden/clients/pull/20448 closes (bitwarden updates electron version)
      {
        name = "bitwarden";
        greedy = true;
      }
      {
        name = "figma";
        greedy = true;
      }
      {
        name = "font-sf-mono";
        greedy = true;
        args = {
          require_sha = false;
        };
      }
      {
        name = "font-sf-pro";
        greedy = true;
        args = {
          require_sha = false;
        };
      }
      {
        name = "google-drive";
        greedy = true;
        args = {
          require_sha = false;
        };
      }
      {
        name = "karabiner-elements";
        greedy = true;
      }
      {
        name = "linear";
        greedy = true;
      }
      {
        name = "microsoft-edge";
        greedy = true;
      }
      {
        name = "nvidia-geforce-now";
        greedy = true;
        args = {
          require_sha = false;
        };
      }
      {
        name = "raspberry-pi-imager";
        greedy = true;
      }
      {
        name = "slack";
        greedy = true;
      }
      {
        name = "spotify";
        greedy = true;
        args = {
          require_sha = false;
        };
      }
      {
        name = "thunderbird";
        greedy = true;
      }
      {
        name = "whatsapp";
        greedy = true;
      }
    ];

    masApps = { };
    onActivation = {
      autoUpdate = false;
      cleanup = "zap";
      upgrade = false;
    };
  };

  nix.settings.experimental-features = "nix-command flakes";
  nix.settings.substituters = [
    # default nixos cace
    "https://cache.nixos.org/"
    # devenv cache
    "https://devenv.cachix.org"
  ];
  nix.settings.trusted-public-keys = [
    # devenv cache
    "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
  ];

  nixpkgs.config = {
    allowUnfree = true;
  };

  programs = {
    zsh = {
      enable = true;
    };

    _1password = {
      enable = true;
    };

    _1password-gui = {
      enable = true;
    };
  };

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  services = {
    sketchybar = {
      enable = true;
      package = pkgs.sketchybar;
      extraPackages = [ pkgs.jq ];
    };

    tailscale = {
      enable = true;
      # extraDaemonFlags = [ "--no-logs-no-support" ];
    };

    yabai = {
      enable = true;
      # SIP needs to be disabled, see: https://github.com/koekeishiya/yabai/wiki#quickstart-guide
      enableScriptingAddition = true;
      package = pkgs.yabai;
      config =
        let
          gap_top = 1;
          gap_bottom = 2;
          gap_left = 2;
          gap_right = 2;
          gap_inner = 2;

          colors_preselect = "0xff9dd274";
        in
        {
          layout = "bsp";
          window_placement = "second_child";
          window_shadow = "float";
          window_topmost = "off";

          external_bar = "all:34:0";

          top_padding = gap_top;
          bottom_padding = gap_bottom;
          left_padding = gap_left;
          right_padding = gap_right;
          window_gap = gap_inner;

          mouse_follows_focus = "autoraise";
          focus_follows_mouse = "off";

          window_opacity = "off";

          insert_feedback_color = colors_preselect;

          split_ratio = 0.50;
          auto_balance = "off";

          mouse_modifier = "fn";
          mouse_action1 = "move";
          mouse_action2 = "resize";
        };
      # TODO: update these rules to actually match correctly + figure out default float positions (center + size)
      extraConfig = ''
        # Load the scripting addition (requires enableScriptingAddition = true)
        sudo yabai --load-sa
        yabai -m signal --add event=dock_did_restart action="sudo yabai --load-sa"

        yabai -m rule --add label='Finder' app='^Finder$' title='(Co(py|nnect)|Move|Info|Pref)' manage=off
        yabai -m rule --add label='Safari' app='^Safari$' title='^(General|(Tab|Password|Website|Extension)s|AutoFill|Se(arch|curity)|Privacy|Advance)$' manage=off
        yabai -m rule --add label='System Settings' app='^System Settings$' title='.*' manage=off
        yabai -m rule --add label='App Store' app='^App Store$' manage=off
        yabai -m rule --add label='Activity Monitor' app='^Activity Monitor$' manage=off
        yabai -m rule --add label='Calculator' app='^Calculator$' manage=off
        yabai -m rule --add label='Dictionary' app='^Dictionary$' manage=off
        yabai -m rule --add label='Software Update' title='Software Update' manage=off
        yabai -m rule --add label='About This Mac' app='System Information' title='About This Mac' manage=off
        yabai -m rule --add label='Raycast Settings' app='Raycast' title='Raycast Settings' manage=off
      '';
    };
  };

  system = {
    activationScripts = {
      postActivation.text = ''
        # rosetta to run x86 on silicon
        softwareupdate --install-rosetta --agree-to-license
      '';
    };

    defaults = {
      ActivityMonitor.IconType = 5;
      controlcenter = {
        BatteryShowPercentage = true;
      };

      dock = {
        autohide = true;
        launchanim = false;
        largesize = 54;
        persistent-apps = [
          "/Applications/WhatsApp.app"
          "/Applications/Slack.app"
          "/Applications/Thunderbird.app"
          # "${pkgs.firefox-devedition}/Applications/Firefox Developer Edition.app"
          "${pkgs.kitty}/Applications/kitty.app"
          "${pkgs.obsidian}/Applications/Obsidian.app"
        ];
        persistent-others = [ ];

        show-recents = false;
      };

      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        CreateDesktop = false;
        FXPreferredViewStyle = "clmv";
        QuitMenuItem = true;
        ShowExternalHardDrivesOnDesktop = true;
        ShowHardDrivesOnDesktop = true;
        ShowMountedServersOnDesktop = true;
        ShowPathbar = true;
      };

      loginwindow = {
        GuestEnabled = false;
      };

      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";
        AppleMeasurementUnits = "Centimeters";
        AppleMetricUnits = 1;
        ApplePressAndHoldEnabled = false;
        AppleShowAllExtensions = true;
        AppleTemperatureUnit = "Celsius";
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticWindowAnimationsEnabled = false;
        "com.apple.keyboard.fnState" = true;
        "com.apple.mouse.tapBehavior" = 1;
      };

      trackpad = {
        Clicking = true;
        FirstClickThreshold = 0;
        SecondClickThreshold = 0;
        TrackpadRightClick = true;
      };
    };

    # FIXME: Migrate user-relevant options to home-manager / monitor where nix-darwin moves them
    primaryUser = "martin";

    stateVersion = 5;
  };

  users.users = {
    martin = {
      name = "martin";
      home = "/Users/martin";
    };
  };
}
