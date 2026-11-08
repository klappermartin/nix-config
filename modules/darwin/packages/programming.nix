{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ast-grep
    bun
    # Include Codex and Claude so CodexBar can find their configurations.
    claude-code
    codex
    codexbar
    colima
    dive
    docker
    # Provides docker-credential-osxkeychain for ~/.docker/config.json.
    docker-credential-helpers
    fx
    google-cloud-sdk
    nixd
    nixfmt
    nodejs_22
    pnpm
    pi-coding-agent
    rainfrog
    ripgrep
    shellcheck
    zed-editor
  ];
}
