{
  inputs,
  nixpkgs,
  pkgs,
  self,
}:
{
  oss-references =
    pkgs.runCommand "oss-references-tests"
      {
        nativeBuildInputs = with pkgs; [
          bash
          git
          coreutils
          findutils
          gnugrep
          gnused
          jq
          shellcheck
        ];
      }
      ''
        shellcheck ${./darwin/home/programs/oss-ref.sh} ${./tests/oss-ref.sh}
        bash ${./tests/oss-ref.sh} ${./darwin/home/programs/oss-ref.sh}
        touch "$out"
      '';

  # Force every host's system evaluation without realizing its whole closure.
  host-evaluation = pkgs.writeText "darwin-host-evaluation.json" (
    builtins.toJSON (
      builtins.mapAttrs (
        _: host: builtins.unsafeDiscardStringContext host.system.drvPath
      ) self.darwinConfigurations
    )
  );

  # Evaluate the portable Home Manager baseline with Linux packages. This
  # checks composition only; it does not build or activate a Linux host.
  home-portability =
    let
      linuxPkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
        overlays = [ inputs.nur.overlays.default ];
      };
      home = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = linuxPkgs;
        modules = [
          ./modules/home/base.nix
          ./modules/home/profiles/personal.nix
          {
            home.username = "evaluation";
            home.homeDirectory = "/home/evaluation";
            workstation.ssh.keyFile = ".ssh/id_ed25519";
          }
        ];
      };
    in
    pkgs.writeText "linux-home-evaluation" (
      builtins.unsafeDiscardStringContext home.activationPackage.drvPath
    );
}
