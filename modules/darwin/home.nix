{
  imports = [
    ../home/base.nix
    ../../darwin/home/desktop.nix
    ../../darwin/home/programs
    ../../darwin/home/services
    ./packages/programming.nix
    ./packages/productivity.nix
    ./packages/communication.nix
    ./packages/other.nix
  ];

  targets.darwin = {
    linkApps.enable = false;
    copyApps.enable = true;
  };

  programs.firefox.darwinDefaultsId = "org.nixos.firefoxdeveloperedition.plist";

  # Load stored SSH key passphrases before Git signing is first used.
  launchd.agents.ssh-add-keychain = {
    enable = true;
    config = {
      ProgramArguments = [
        "/usr/bin/ssh-add"
        "--apple-load-keychain"
        "-q"
      ];
      RunAtLoad = true;
    };
  };
}
