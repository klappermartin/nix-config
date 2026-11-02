{ pkgs, ... }:
{
  home = {
    username = "martin";
    homeDirectory = "/Users/martin";
    stateVersion = "25.05";
    packages = with pkgs; [
      git
      jq
      nixd
      nixfmt
      ripgrep
      shellcheck
    ];
  };

  # Plain OpenCode: no model/provider credentials, plugins, or MCP servers.
  programs.opencode = {
    enable = true;
    package = pkgs.opencode;
    settings = {
      "$schema" = "https://opencode.ai/config.json";
      update = "disable";
      plugins = [ ];
      mcp.servers = { };
    };
  };
}
