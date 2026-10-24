{
  pkgs,
  config,
  username,
  ...
}:
{
  environment = {
    # reference xcode from the system closure so it's gc-rooted (it has no bin/share to link via systemPackages)
    # TODO: re-enable once Xcode 26.5 is re-added to the store (needs Apple ID for download)
    # etc."xcode".source = pkgs.darwin.xcode_26_5_Apple_silicon;
    # symlink system packages to home manager zsh for completion access
    pathsToLink = [ "/share/zsh/" ];
    systemPackages = with pkgs; [
      devenv
      # keepassxc
    ];
  };

  nix.settings.experimental-features = "nix-command flakes";
  # merged with nix-darwin's default (cache.nixos.org)
  nix.settings.substituters = [
    # devenv cache
    "https://devenv.cachix.org"
  ];
  nix.settings.trusted-public-keys = [
    # devenv cache
    "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
  ];

  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config.allowUnfree = true;
  };

  nix.optimise.automatic = true;

  programs = {
    # runs `nh clean all` as root, so system generations are collected too
    nh = {
      enable = true;
      flake = "${config.users.users.${username}.home}/nix";
      clean = {
        enable = true;
        extraArgs = "--keep 5 --keep-since 7d";
      };
    };

    zsh = {
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
      extraConfig = ''
        # Load the scripting addition (requires enableScriptingAddition = true)
        sudo yabai --load-sa
        yabai -m signal --add label='load-sa' event=dock_did_restart action="sudo yabai --load-sa"

        # Match accessibility dialogs, not arbitrary Finder folders / browser
        # tabs whose titles happen to contain "Info", "General", etc.
        yabai -m rule --add label='Finder' app='^Finder$' subrole='^AX(System)?Dialog$' manage=off
        yabai -m rule --add label='Safari' app='^Safari$' subrole='^AX(System)?Dialog$' manage=off
        yabai -m rule --add label='Finder Settings' app='^Finder$' title='^Finder (Settings|Preferences)$' manage=off
        yabai -m rule --add label='System Settings' app='^System Settings$' manage=off

        # Resizable utility windows: centered at 2/3 of the display. Limit the
        # grid to standard windows so child dialogs keep their natural size.
        yabai -m rule --add label='App Store' app='^App Store$' manage=off
        yabai -m rule --add label='App Store layout' app='^App Store$' subrole='^AXStandardWindow$' grid=6:6:1:1:4:4
        yabai -m rule --add label='Activity Monitor' app='^Activity Monitor$' manage=off
        yabai -m rule --add label='Activity Monitor layout' app='^Activity Monitor$' subrole='^AXStandardWindow$' grid=6:6:1:1:4:4
        yabai -m rule --add label='Calculator' app='^Calculator$' manage=off
        yabai -m rule --add label='Dictionary' app='^Dictionary$' manage=off
        yabai -m rule --add label='Dictionary layout' app='^Dictionary$' subrole='^AXStandardWindow$' grid=6:6:1:1:4:4
        yabai -m rule --add label='Software Update' app='^(Software Update|System Settings|System Preferences)$' title='^Software Update$' manage=off
        yabai -m rule --add label='About This Mac' app='^System Information$' title='^About This Mac$' manage=off
        yabai -m rule --add label='Raycast Settings' app='^Raycast$' title='^Raycast (Settings|Preferences)$' manage=off
      '';
    };
  };

  system = {
    defaults = {
      ActivityMonitor.IconType = 5;
      controlcenter = {
        BatteryShowPercentage = true;
      };

      dock = {
        autohide = true;
        launchanim = false;
        largesize = 54;
        persistent-apps =
          let
            hm = config.home-manager.users.${username};
            hmApp = name: "${hm.home.homeDirectory}/${hm.targets.darwin.copyApps.directory}/${name}.app";
          in
          map hmApp [
            "WhatsApp"
            "Slack"
            "Thunderbird"
            "Firefox Developer Edition"
            "kitty"
            "Obsidian"
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

    primaryUser = username;

    stateVersion = 5;
  };

  users.users.${username}.home = "/Users/${username}";
}
