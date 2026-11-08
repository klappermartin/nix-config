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
    # Managed key comes from workstation.ssh.keyFile (each host declares it,
    # see modules/home/ssh-options.nix); per-machine overrides
    # can stay in ~/.ssh/config.d/*.conf, which is included before this.
    settings."github.com" = {
      AddKeysToAgent = "yes";
      UseKeychain = "yes";
      IdentityFile = "~/${config.workstation.ssh.keyFile}";
    };
  };

  home.activation.sshConfigDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p -m 700 ${lib.escapeShellArg "${config.home.homeDirectory}/.ssh/config.d"}
  '';
}
