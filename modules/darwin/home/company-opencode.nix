{ lib, pkgs, ... }:
{
  home.packages = [ pkgs.codebase-memory-mcp ];

  programs.opencode = {
    # The former standalone company profile deliberately had no auth plugin.
    settings.plugins = lib.mkForce [ ];
    settings.mcp.servers = {
      # Keep the externally approved research MCPs from the shared module, but
      # do not expose personal work integrations on the company device.
      figma.disabled = true;
      linear.disabled = true;

      codebase_memory = {
        type = "local";
        command = [ (lib.getExe pkgs.codebase-memory-mcp) ];
      };
    };
  };
}
