{
  config,
  lib,
  pkgs,
  ...
}:
let
  # These are display-local indices, unlike Sketchybar's global space slots.
  spaceKeys = map toString (lib.range 1 config.workstation.desktop.spaceKeysPerDisplay);
  forEachSpace =
    action:
    lib.concatMapStringsSep "\n" (
      binding:
      lib.concatMapStringsSep "\n" (
        n:
        "${binding} - ${n} : SPACES=($(yabai -m query --displays --display | jq '.spaces[]')) && [[ -n $SPACES[${n}] ]] && ${action} $SPACES[${n}]"
      ) spaceKeys
    );
  focusSpace = forEachSpace "yabai -m space --focus" [
    "lalt"
    "ralt"
  ];
  moveToSpace = forEachSpace "yabai -m window --space" [
    "shift + lalt"
    "shift + ralt"
  ];
in
{
  launchd.agents.skhd = {
    restartTriggers = [ config.xdg.configFile."skhd/skhdrc".source ];
    config.EnvironmentVariables = {
      SHELL = "${pkgs.zsh}/bin/zsh";
      XDG_CONFIG_HOME = config.xdg.configHome;
      PATH =
        lib.makeBinPath [
          pkgs.yabai
          pkgs.jq
          pkgs.sketchybar
          config.services.skhd.package
        ]
        + ":/usr/bin:/bin:/usr/sbin:/sbin";
    };
  };

  # Retire skhd --install-service's old registration before HM starts its agent.
  # Preserve the old plist outside LaunchAgents for inspection/recovery.
  home.activation.retireLegacySkhd =
    lib.hm.dag.entryBetween [ "setupLaunchAgents" ] [ "writeBoundary" ]
      ''
        legacy=${lib.escapeShellArg "${config.home.homeDirectory}/Library/LaunchAgents/com.koekeishiya.skhd.plist"}
        retired=${lib.escapeShellArg "${config.xdg.stateHome}/home-manager/retired-launchagents"}
        if /bin/launchctl print "gui/$UID/com.koekeishiya.skhd" >/dev/null 2>&1; then
          version=$(/usr/bin/sw_vers --productVersion)
          if [[ "''${version%%.*}" -ge 26 ]]; then
            run /bin/launchctl bootout --wait "gui/$UID/com.koekeishiya.skhd"
          else
            run /bin/launchctl bootout "gui/$UID/com.koekeishiya.skhd"
            run sleep 1
          fi
        fi
        if [[ -e "$legacy" || -L "$legacy" ]]; then
          run mkdir -p "$retired"
          run ${pkgs.coreutils}/bin/mv --backup=numbered -T -- "$legacy" "$retired/com.koekeishiya.skhd.plist"
        fi
        run mkdir -p ${lib.escapeShellArg "${config.home.homeDirectory}/Library/Logs/skhd"}
      '';

  services.skhd = {
    enable = true;
    package = pkgs.skhd;
    # Copied from https://github.com/FelixKratz/dotfiles/blob/master/.config/skhd/skhdrc
    config = ''
      ## Navigation (lalt - ...)
      # Space Navigation: numbered spaces on the focused display
      ${focusSpace}

      # Window Navigation (through display borders): lalt - {h, j, k, ;}
      lalt - h    : yabai -m window --focus west  || yabai -m display --focus west
      lalt - j    : yabai -m window --focus south || yabai -m display --focus south
      lalt - k    : yabai -m window --focus north || yabai -m display --focus north
      lalt - l    : yabai -m window --focus east  || yabai -m display --focus east

      # Extended Window Navigation: lalt - {;, '}
      lalt - 0x29 : yabai -m window --focus first
      lalt - 0x27 : yabai -m window --focus  last

      # Float / Unfloat window: lalt - space
      lalt - space : yabai -m window --toggle float

      # Make window zoom to fullscreen: shift + lalt - f
      shift + lalt - f : yabai -m window --toggle zoom-fullscreen

      # Make window zoom to parent node: lalt - f
      lalt - f : yabai -m window --toggle zoom-parent

      ## Window Movement (shift + lalt - ...)
      # Moving windows in spaces: shift + lalt - {j, k, l, ;}
      shift + lalt - h : yabai -m window --warp west || (yabai -m window --display west && yabai -m display --focus west && yabai -m window --warp last) || yabai -m window --move rel:-10:0
      shift + lalt - j : yabai -m window --warp south || (yabai -m window --display south && yabai -m display --focus south) || yabai -m window --move rel:0:10
      shift + lalt - k : yabai -m window --warp north || (yabai -m window --display north && yabai -m display --focus north) || yabai -m window --move rel:0:-10
      shift + lalt - l : yabai -m window --warp east || (yabai -m window --display east && yabai -m display --focus east && yabai -m window --warp first) || yabai -m window --move rel:10:0

      # Toggle split orientation of the selected windows node: shift + lalt - s
      shift + lalt - s : yabai -m window --toggle split

      # Moving windows between spaces: shift + {lalt, ralt} + number; previous/next: p/n
      ${moveToSpace}

      shift + lalt - p : yabai -m window --space prev && yabai -m space --focus prev
      shift + lalt - n : yabai -m window --space next && yabai -m space --focus next

      # Mirror Space on X and Y Axis: shift + lalt - {x, y}
      shift + lalt - x : yabai -m space --mirror x-axis
      shift + lalt - y : yabai -m space --mirror y-axis

      ## Stacks (shift + ctrl - ...)
      # Add the active window to the window or stack to the {direction}: shift + ctrl - {h, j, k, ;}
      shift + ctrl - h    : yabai -m window  west --stack $(yabai -m query --windows --window | jq -r '.id')
      shift + ctrl - j    : yabai -m window south --stack $(yabai -m query --windows --window | jq -r '.id')
      shift + ctrl - k    : yabai -m window north --stack $(yabai -m query --windows --window | jq -r '.id')
      shift + ctrl - l    : yabai -m window  east --stack $(yabai -m query --windows --window | jq -r '.id')

      # Stack Navigation: shift + ctrl - {n, p}
      shift + ctrl - n : yabai -m window --focus stack.next
      shift + ctrl - p : yabai -m window --focus stack.prev

      ## Resize (ctrl + lalt - ...)
      # Resize windows: ctrl + lalt - {h, j, k, ;}
      ctrl + lalt - h    : yabai -m window --resize right:-100:0 || yabai -m window --resize left:-100:0
      ctrl + lalt - j    : yabai -m window --resize bottom:0:100 || yabai -m window --resize top:0:100
      ctrl + lalt - k    : yabai -m window --resize bottom:0:-100 || yabai -m window --resize top:0:-100
      ctrl + lalt - l    : yabai -m window --resize right:100:0 || yabai -m window --resize left:100:0

      # Equalize size of windows: ctrl + lalt - e
      ctrl + lalt - e : yabai -m space --balance

      # Enable / Disable gaps in current workspace: ctrl + lalt - g
      ctrl + lalt - g : yabai -m space --toggle padding; yabai -m space --toggle gap

      ## Insertion (shift + ctrl + lalt - ...)
      # Set insertion point for focused container: shift + ctrl + lalt - {h, j, k, ;, s}
      shift + ctrl + lalt - h : yabai -m window --insert west
      shift + ctrl + lalt - j : yabai -m window --insert south
      shift + ctrl + lalt - k : yabai -m window --insert north
      shift + ctrl + lalt - l : yabai -m window --insert east
      shift + ctrl + lalt - s : yabai -m window --insert stack

      # New window in hor./ vert. splits for all applications with yabai
      lalt - s : yabai -m window --insert east;  skhd -k "cmd - n"
      lalt - v : yabai -m window --insert south; skhd -k "cmd - n"

      # Toggle sketchybar
      shift + lalt - space : sketchybar --bar hidden=toggle
    '';
  };
}
