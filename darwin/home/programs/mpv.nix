# taken from gvolpe: https://github.com/gvolpe/nix-config/blob/cac3d57ee34bc1cfd368f7848717c5c17071c8d6/home/programs/mpv/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:

let
  # ff2mpv firefox extension native client — wiring differs by platform, see
  # `home.file` below for the system-dependent bits.
  #
  # The native-messaging host manifest location is system-dependent:
  #   - macOS: ~/Library/Application Support/Mozilla/NativeMessagingHosts/
  #   - Linux: ~/.mozilla/native-messaging-hosts/
  # Firefox only scans one directory per OS; a manifest located elsewhere is
  # silently ignored, which previously made the "Play in mpv" button do nothing
  # even though the manifest was on disk.
  #
  # On macOS, GUI applications inherit PATH from launchd (no Nix profile dirs),
  # so the upstream ff2mpv.py can't find `mpv` on its own. The wrapper below
  # supplies the configured mpv package before exec'ing the upstream script.
  ff2mpvLauncher = pkgs.writeShellScriptBin "ff2mpv-launcher" ''
    export PATH="${lib.makeBinPath [ config.programs.mpv.package ]}:$PATH"
    exec "${pkgs.ff2mpv}/bin/ff2mpv.py" "$@"
  '';
in
{
  home.file =
    if pkgs.stdenv.hostPlatform.isDarwin then
      {
        # macOS: Firefox only scans this NativeMessagingHosts dir, NOT ~/.mozilla/.
        "Library/Application Support/Mozilla/NativeMessagingHosts/ff2mpv.json".text = builtins.toJSON {
          name = "ff2mpv";
          description = "ff2mpv's external manifest";
          path = "${ff2mpvLauncher}/bin/ff2mpv-launcher";
          type = "stdio";
          allowed_extensions = [ "ff2mpv@yossarian.net" ];
        };
      }
    else
      {
        # Linux: ~/.mozilla/native-messaging-hosts/ — what FF scans on Linux.
        ".mozilla/native-messaging-hosts/ff2mpv.json".source =
          "${pkgs.ff2mpv}/lib/mozilla/native-messaging-hosts/ff2mpv.json";
      };

  programs.mpv = {
    enable = true;
    bindings = {
      "BS" = "cycle pause";
      "SPACE" = "cycle pause";

      "\\" = "set speed 1.0";

      "UP" = "add volume 2";
      "DOWN" = "add volume -2";

      "PGUP" = "add chapter -1";
      "PGDWN" = "add chapter 1";

      "MOUSE_BTN3" = "add volume 2";
      "MOUSE_BTN4" = "add volume -2";

      "MOUSE_BTN7" = "add chapter -1";
      "MOUSE_BTN8" = "add chapter 1";

      "Alt+RIGHT" = "add video-rotate 90";
      "Alt+LEFT" = "add video-rotate -90";

      "h" = "seek -5";
      "j" = "add volume -2";
      "k" = "add volume 2";
      "l" = "seek 5";

      "Shift+LEFT" = "seek -60";
      "Shift+RIGHT" = "seek +60";

      "Ctrl+h" = "add chapter -1";
      "Ctrl+j" = "repeatable playlist-prev";
      "Ctrl+k" = "repeatable playlist-next";
      "Ctrl+l" = "add chapter 1";

      "J" = "cycle sub";
      "L" = "ab_loop";

      "a" = "add audio-delay -0.001";
      "s" = "add audio-delay +0.001";

      "O" = "cycle osc; cycle osd-bar";
    };

    config = {
      volume = 100;
      volume-max = 200;
      force-window = "yes";
      keep-open = "no";
      osc = "no";
      osd-bar = "no";
    };
  };
}
