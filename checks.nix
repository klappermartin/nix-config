{
  inputs,
  nixpkgs,
  pkgs,
  self,
}:
let
  ossRefSources = import ./darwin/home/programs/oss-ref/sources.nix;
  ossRefSourcePaths = builtins.concatStringsSep " " (map toString ossRefSources);
in
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
        script="$TMPDIR/oss-ref.sh"
        cat ${ossRefSourcePaths} > "$script"
        shellcheck "$script" ${./tests/oss-ref.sh}
        bash ${./tests/oss-ref.sh} "$script"
        OSS_REF_SOURCE_ROOT=${./.} bash ${./tests/oss-ref.sh}
        touch "$out"
      '';

  opencode-config =
    pkgs.runCommand "opencode-config-tests"
      {
        nativeBuildInputs = with pkgs; [
          bash
          gnugrep
        ];
      }
      ''
        bash ${./tests/opencode-config.sh} ${./.}
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
