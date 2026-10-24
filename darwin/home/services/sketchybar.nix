{ pkgs, ... }:

{
  home.file = {
    # Deploy the Lua config files
    ".config/sketchybar" = {
      source = ../sketchybar;
      recursive = true;
      onChange = "${pkgs.sketchybar}/bin/sketchybar --reload";
    };

    # Symlink sbarlua module
    ".local/share/sketchybar_lua/sketchybar.so" = {
      source = "${pkgs.sbarlua}/lib/lua/${pkgs.lua55Packages.lua.luaversion}/sketchybar.so";
      onChange = "${pkgs.sketchybar}/bin/sketchybar --reload";
    };

    # Generate sketchybarrc entry point
    ".config/sketchybar/sketchybarrc" = {
      text = ''
        #!/usr/bin/env ${pkgs.lua55Packages.lua}/bin/lua
        -- Load the sketchybar-package and prepare the helper binaries
        require("helpers")
        require("init")
      '';
      executable = true;
      onChange = "${pkgs.sketchybar}/bin/sketchybar --reload";
    };
  };
}
