{
  pkgs,
  ...
}:
{
  imports = [
    ./firefox.nix
    ./git.nix
    ./ghostty.nix
    ./kitty.nix
    ./mpv.nix
    ./opencode
    ./oss-references.nix
    ./tmux.nix
    ./vscodium.nix
    ./zsh.nix
  ];

  programs = {
    home-manager.enable = true;

    bash.enable = true;

    btop = {
      enable = true;
      # TODO: settings = {};
    };

    chromium = {
      enable = true;
      package = pkgs.google-chrome;
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      # tmux.enableShellIntegrationOptions = [];
      # TODO: fzf history settings
    };

    gpg.enable = true;

    lsd = {
      enable = true;
      enableZshIntegration = true;
      # TODO: Custom colors and icons
    };

    neovim = {
      enable = true;
      vimAlias = true;

      # explicit due to default change after current stateVersion
      withPython3 = false;
      withRuby = false;
    };

    oss-references = {
      enable = true;
    };

    pay-respects = {
      enable = true;
      enableZshIntegration = true;
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
