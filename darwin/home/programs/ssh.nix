{ config, lib, ... }:
{
  programs.ssh = {
    enable = true;
    # Use Apple's client for Keychain support.
    package = null;
    enableDefaultConfig = false;
    # Local hosts/identities remain editable without rebuilding. Includes come
    # before managed hosts, so local scalar options take precedence.
    includes = [
      "~/.ssh/config.d/*.conf"
      "~/.colima/ssh_config"
    ];
    settings."github.com" = {
      AddKeysToAgent = "yes";
      UseKeychain = "yes";
      IdentityFile = "~/.ssh/id_ed25519";
    };
  };

  home.activation.sshConfigDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p -m 700 ${lib.escapeShellArg "${config.home.homeDirectory}/.ssh/config.d"}
  '';
}
