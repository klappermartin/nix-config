{
  inputs,
  nixpkgs,
  pkgs,
  self,
}:
let
  ossRef = pkgs.callPackage ./darwin/home/programs/oss-ref/package.nix { };
in
{
  oss-references =
    pkgs.runCommand "oss-references-tests"
      {
        nativeBuildInputs = with pkgs; [
          git
          basedpyright
          python3Packages.pytest
          python3Packages.radon
          python3Packages.vulture
          refurb
          ruff
          ossRef
        ];
      }
      ''
        cd ${./.}
        ruff check --no-cache darwin/home/programs/oss-ref/oss_ref tests/oss_ref
        refurb darwin/home/programs/oss-ref/oss_ref tests/oss_ref -- --cache-dir "$TMPDIR/mypy-cache"
        basedpyright ${./darwin/home/programs/oss-ref}
        vulture darwin/home/programs/oss-ref/oss_ref --min-confidence 100
        radon cc --min B --show-complexity darwin/home/programs/oss-ref/oss_ref
        OSS_REF_BIN=${ossRef}/bin/oss-ref pytest -p no:cacheprovider ${./tests/oss_ref}
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
