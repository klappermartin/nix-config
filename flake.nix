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

    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
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
      nixpkgs,
      nixpkgs-stable-2511,
      home-manager,
      darwin,
      nix-homebrew,
      ...
    }:
    let
      username = "martin";
    in
    {
      formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt;
      darwinConfigurations = {
        "mb-pro" = darwin.lib.darwinSystem rec {
          system = "aarch64-darwin";
          specialArgs = {
            inherit inputs username;
          };
          modules = [
            ./darwin/system/configuration.nix
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                enable = true;
                enableRosetta = true;
                user = username;
                taps = {
                  "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
                  "homebrew/homebrew-core" = inputs.homebrew-core;
                  "homebrew/homebrew-cask" = inputs.homebrew-cask;
                };
                mutableTaps = false;
              };
            }
            home-manager.darwinModules.home-manager
            ({ pkgs, ... }: {
              nixpkgs.overlays = [
                inputs.nur.overlays.default
              ];
              home-manager = {
                extraSpecialArgs = {
                  inherit inputs;
                  # Newer oxker releases fail macOS snapshot tests: mrjackwills/oxker#73.
                  oxker-package = nixpkgs-stable-2511.legacyPackages.${system}.oxker;
                };

                useGlobalPkgs = true;
                useUserPackages = true;
                users.${username} = {
                  imports = [
                    ./darwin/home/home.nix
                    ./darwin/home/sketchybar/sketchybar.nix
                  ];
                };
                backupCommand = "${
                  pkgs.writeShellApplication {
                    name = "home-manager-backup";
                    runtimeInputs = [ pkgs.coreutils ];
                    text = ''
                      file=$1
                      if [[ -e "$file.backup" || -L "$file.backup" ]]; then
                        mv -fT -- "$file.backup" "$file.backup.2"
                      fi
                      mv -T -- "$file" "$file.backup"
                    '';
                  }
                }/bin/home-manager-backup";
              };
            })
          ];
        };
      };
    };
}
