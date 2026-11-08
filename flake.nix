{
  description = "5head config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable-2511.url = "github:NixOS/nixpkgs/release-25.11";

    darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      darwin,
      ...
    }:
    let
      mkDarwin =
        host:
        darwin.lib.darwinSystem {
          specialArgs = { inherit inputs; };
          modules = [ host ];
        };
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
    in
    {
      formatter.aarch64-darwin = pkgs.nixfmt-tree;
      packages.aarch64-darwin.darwin-rebuild = darwin.packages.aarch64-darwin.darwin-rebuild;
      darwinConfigurations = {
        mb-pro = mkDarwin ./hosts/mb-pro;
        mb-pro-m5 = mkDarwin ./hosts/mb-pro-m5;
      };
      checks.aarch64-darwin = {
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
        host-policy =
          let
            personal = self.darwinConfigurations.mb-pro.config;
            company = self.darwinConfigurations.mb-pro-m5.config;
            personalExtensions =
              personal.home-manager.users.martin.programs.firefox.profiles.dev-edition-default.extensions.packages;
            companyExtensions =
              company.home-manager.users."martin.klapper".programs.firefox.profiles.dev-edition-default.extensions.packages;
            extensionPaths = map (package: package.outPath);
            hasPackage =
              name: packages:
              builtins.any (package: builtins.match "^${name}(-.*)?$" package.name != null) packages;
            hasCask = name: casks: builtins.any (cask: cask.name == name) casks;
          in
          assert personal.services.tailscale.enable;
          assert !company.services.tailscale.enable;
          assert personal.homebrew.onActivation.cleanup == "none";
          assert company.homebrew.onActivation.cleanup == "none";
          assert hasPackage "unpaywall" personalExtensions;
          assert !hasPackage "unpaywall" companyExtensions;
          assert hasPackage "ff2mpv" personalExtensions;
          assert !hasPackage "ff2mpv" companyExtensions;
          assert hasPackage "prismlauncher" personal.home-manager.users.martin.home.packages;
          assert !hasPackage "prismlauncher" company.home-manager.users."martin.klapper".home.packages;
          assert hasCask "spotify" personal.homebrew.casks;
          assert hasCask "spotify" company.homebrew.casks;
          assert hasCask "nvidia-geforce-now" personal.homebrew.casks;
          assert !hasCask "nvidia-geforce-now" company.homebrew.casks;
          assert personal.home-manager.users.martin.home.sessionVariables.OPENCODE_DB == "opencode-v2.db";
          assert
            company.home-manager.users."martin.klapper".home.sessionVariables.OPENCODE_DB == "opencode.db";
          assert
            personal.home-manager.users.martin.programs.opencode.settings.plugins
            == [ "@ex-machina/opencode-anthropic-auth@2.0.0-next.5" ];
          assert company.home-manager.users."martin.klapper".programs.opencode.settings.plugins == [ ];
          assert
            !(personal.home-manager.users.martin.programs.opencode.settings.mcp.servers ? codebase_memory);
          assert
            company.home-manager.users."martin.klapper".programs.opencode.settings.mcp.servers
              ? codebase_memory;
          assert !((personal.home-manager.users.martin.programs.opencode.settings.providers or { }) ? ds4);
          assert
            (company.home-manager.users."martin.klapper".programs.opencode.settings.providers or { }) ? ds4;
          assert !hasPackage "ollama" personal.home-manager.users.martin.home.packages;
          assert hasPackage "ollama" company.home-manager.users."martin.klapper".home.packages;
          assert extensionPaths personalExtensions != extensionPaths companyExtensions;
          pkgs.writeText "darwin-host-policy" "Host policies evaluated successfully.\n";
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
      };
    };
}
