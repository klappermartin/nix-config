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
      nixpkgs,
      home-manager,
      darwin,
      nix-homebrew,
      ...
    }:
    let
      username = "martin";
    in
    {
      formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-tree;
      darwinConfigurations = {
        "mb-pro" = darwin.lib.darwinSystem {
          specialArgs = {
            inherit inputs username;
          };
          modules = [
            ./darwin/system/configuration.nix
            ./darwin/system/overlays.nix
            nix-homebrew.darwinModules.nix-homebrew
            ./darwin/system/homebrew.nix
            home-manager.darwinModules.home-manager
            ./darwin/system/home-manager.nix
          ];
        };
      };
    };
}
