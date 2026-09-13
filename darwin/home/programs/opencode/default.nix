{
  config,
  lib,
  pkgs,
  ...
}:
let
  switcher = pkgs.writeShellApplication {
    name = "activate-oh-my-openagent-profile.sh";
    runtimeInputs = [ pkgs.coreutils ];
    text = builtins.readFile ./activate-oh-my-openagent-profile.sh;
  };
  omoDirectory = "${config.home.homeDirectory}/.omo";
in
{
  programs.opencode = {
    enable = true;
    settings = {
      plugin = [
        "@ex-machina/opencode-anthropic-auth@1.6.0"
        "oh-my-openagent@4.19.4"
      ];
      mcp = {
        linear = {
          type = "remote";
          url = "https://mcp.linear.app/mcp";
          oauth = { };
        };
        figma = {
          type = "remote";
          url = "http://127.0.0.1:3845/mcp";
        };
      };
    };
    tui.plugin = [ "oh-my-openagent@latest" ];
  };

  home.packages = [ switcher ];
  home.file = {
    ".omo/omo.anthropic.jsonc".source = ./omo.anthropic.jsonc;
    ".omo/omo.openai.jsonc".source = ./omo.openai.jsonc;
    ".omo/omo.opencode-go.jsonc".source = ./omo.opencode-go.jsonc;
  };
  xdg.configFile."opencode/activate-oh-my-openagent-profile.sh".source =
    "${switcher}/bin/activate-oh-my-openagent-profile.sh";

  # The switcher owns the active file; rebuilds must preserve the selected profile.
  home.activation.initializeOmoProfile = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [[ ! -e ${lib.escapeShellArg "${omoDirectory}/omo.jsonc"} && ! -L ${lib.escapeShellArg "${omoDirectory}/omo.jsonc"} ]]; then
      run ${pkgs.coreutils}/bin/ln -s omo.anthropic.jsonc ${lib.escapeShellArg "${omoDirectory}/omo.jsonc"}
    fi
  '';
}
