{ pkgs, ... }:
{
  programs.firefox.profiles.dev-edition-default.extensions.packages =
    import ./extensions.nix { inherit pkgs; }
    ++ [
      pkgs.nur.repos.rycee.firefox-addons.ff2mpv
      pkgs.nur.repos.rycee.firefox-addons.unpaywall
    ];
}
