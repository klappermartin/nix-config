{ lib, pkgs, ... }:
{
  home.packages = [ pkgs.codebase-memory-mcp ];

  programs.opencode = {
    # The former standalone company profile deliberately had no auth plugin.
    settings.plugins = lib.mkForce [ ];
    settings.mcp.servers.codebase_memory = {
      type = "local";
      command = [ (lib.getExe pkgs.codebase-memory-mcp) ];
    };
  };
}
