{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    age
    ast-grep
    bat
    bc
    bun
    # bitwarden-cli
    # TODO: Move back to unstable once nixpkgs#523142 (compiler-rt darwin fix) is merged
    # TODO: Re-enable after https://github.com/bitwarden/clients/pull/20448 closes (bitwarden electron upgrade)
    # pkgs-stable.bitwarden-desktop
    # ! Include codex and claude so codexbar can find their configurations
    claude-code
    codex
    codexbar
    colima
    discordo
    dive
    discord
    docker
    # provides docker-credential-osxkeychain (referenced by ~/.docker/config.json credsStore)
    docker-credential-helpers
    # TODO: Re-enable and test if profiles are working for devedition again
    # firefox-devedition
    fzf
    fx
    jq
    gdu
    git
    gh-eco
    gnupg
    google-chrome
    google-cloud-sdk
    hyperfine
    kitty
    nerd-fonts.jetbrains-mono
    mqttui
    mutt
    nixd
    nixfmt
    nmap
    nodejs_22
    obsidian
    osu-lazer-bin
    procs
    pi-coding-agent
    pinentry-tty
    postman
    prismlauncher
    rainfrog
    ripgrep
    raycast
    sbarlua
    shellcheck
    speedtest-cli
    tailscale
    telegram-desktop
    tmux
    tmuxPlugins.tokyo-night-tmux
    tmuxPlugins.yank
    ttyper
    vscodium
    zed-editor
    zsh
    zsh-powerlevel10k
  ];
}
