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
        # Force every host's system evaluation without realizing its whole closure.
        host-evaluation = pkgs.writeText "darwin-host-evaluation.json" (
          builtins.toJSON (
            builtins.mapAttrs (
              _: host: builtins.unsafeDiscardStringContext host.system.drvPath
            ) self.darwinConfigurations
          )
        );
      };
    };
}
