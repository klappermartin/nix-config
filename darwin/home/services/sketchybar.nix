{ config, pkgs, ... }:

{
  xdg.configFile = {
    # Deploy the Lua config files
    "sketchybar" = {
      source = ../sketchybar;
      recursive = true;
      onChange = "${pkgs.sketchybar}/bin/sketchybar --reload";
    };

    "sketchybar/host.lua" = {
      text = ''
        return {
          network_interface = ${builtins.toJSON config.workstation.desktop.networkInterface},
          space_count = ${toString config.workstation.desktop.spaceCount},
        }
      '';
      onChange = "${pkgs.sketchybar}/bin/sketchybar --reload";
    };

    # Generate sketchybarrc entry point
    "sketchybar/sketchybarrc" = {
      text = ''
        #!${pkgs.lua55Packages.lua}/bin/lua
        -- Use the configured module directly rather than a reconstructed home path.
        require("helpers")("${pkgs.sbarlua}/lib/lua/${pkgs.lua55Packages.lua.luaversion}/?.so")
        require("init")
      '';
      executable = true;
      onChange = "${pkgs.sketchybar}/bin/sketchybar --reload";
    };
  };
}
