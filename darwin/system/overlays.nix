{ inputs, ... }:
{
  nixpkgs.overlays = [
    inputs.nur.overlays.default
    (final: prev: {
      # Newer oxker releases fail macOS snapshot tests: mrjackwills/oxker#73.
      oxker = inputs.nixpkgs-stable-2511.legacyPackages.${prev.stdenv.hostPlatform.system}.oxker;
    })
  ];
}
