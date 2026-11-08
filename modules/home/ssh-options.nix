{ lib, ... }:
{
  options.workstation.ssh.keyFile = lib.mkOption {
    # Git signing is mandatory, so every host declares its own key.
    type = lib.types.str;
    description = "Path of the machine's SSH private key, relative to the home directory.";
  };
}
