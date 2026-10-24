{
  pkgs,
  config,
  ...
}:
{
  # ~/.p10k.zsh is a read-only link; to reconfigure, `rm ~/.p10k.zsh && p10k configure`,
  # then copy the generated file back over ./p10k.zsh
  home.file.".p10k.zsh".source = ./p10k.zsh;

  home.sessionVariables = {
    TERMINAL = "kitty";
    EDITOR = "zeditor --wait";
    # use fake omz cache dir for completions
    ZSH_CACHE_DIR = "${config.home.homeDirectory}/.cache/oh-my-zsh";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;

    # p10k config
    # you should use position after the commands output
    initContent = ''
      # extra config (before aliases)
      source ~/.p10k.zsh
      export YSU_MESSAGE_POSITION="after"
      unalias rm # unalias rm -i from common-aliases
    '';

    plugins =
      with pkgs;
      let
        # Using lots of plugins from omz: https://github.com/ohmyzsh/ohmyzsh
        omzPlugins = "${oh-my-zsh}/share/oh-my-zsh";
      in
      [
        {
          name = "zsh-powerlevel10k";
          src = "${zsh-powerlevel10k}/share/zsh-powerlevel10k/";
          file = "powerlevel10k.zsh-theme";
        }
        {
          name = "zsh-you-should-use";
          src = "${zsh-you-should-use}/share/zsh/plugins/you-should-use";
          file = "you-should-use.plugin.zsh";
        }
        # Omz plugins
        {
          name = "directories";
          src = "${omzPlugins}/lib";
          file = "directories.zsh";
        }
        {
          name = "git";
          src = "${omzPlugins}/plugins/git";
          file = "git.plugin.zsh";
        }
        {
          name = "git-commit";
          src = "${omzPlugins}/plugins/git-commit";
          file = "git-commit.plugin.zsh";
        }
        {
          name = "common-aliases";
          src = "${omzPlugins}/plugins/common-aliases";
          file = "common-aliases.plugin.zsh";
        }
        {
          name = "gh";
          src = "${omzPlugins}/plugins/gh";
          file = "gh.plugin.zsh";
        }
        {
          name = "docker";
          src = "${omzPlugins}/plugins/docker";
          file = "docker.plugin.zsh";
        }
        {
          name = "docker-compose";
          src = "${omzPlugins}/plugins/docker-compose";
          file = "docker-compose.plugin.zsh";
        }
      ];

    syntaxHighlighting.enable = true;
    shellAliases = {
      myip = "curl https://ipinfo.io/json";
      speedtest = "${pkgs.speedtest-cli}/bin/speedtest-cli";
      pn = "pnpm";
    };
    # TODO: History options
  };
}
