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
    bitwarden-cli
    bitwarden-desktop
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
    fx
    jq
    gdu
    google-cloud-sdk
    handy
    hyperfine
    mqttui
    mutt
    nixd
    nixfmt
    nmap
    nodejs_22
    pnpm
    obsidian
    osu-lazer-bin
    procs
    pi-coding-agent
    # TODO: Temporary LANG override to avoid a Darwin bash 5.3 segfault in wrapQtAppsHook.
    # Remove once https://github.com/NixOS/nixpkgs/pull/565511 is merged.
    (prismlauncher.overrideAttrs { LANG = "C"; })
    rainfrog
    ripgrep
    raycast
    shellcheck
    slack
    speedtest-cli
    telegram-desktop
    thunderbird
    ttyper
    whatsapp-for-mac
    zed-editor
  ];
}
