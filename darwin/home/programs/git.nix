{
  config,
  pkgs,
  ...
}:
let
  email = "64156820+klappermartin@users.noreply.github.com";
  sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIESQFjRlkApLrMLCnGRedOl12/Zvf5V5wZsUJQoRNaZ9";
in
{
  programs.git = {
    enable = true;
    signing = {
      format = "ssh";
      # must be added on GitHub as a *signing* key
      key = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
      signByDefault = true;
      # lets `git log --show-signature` verify own commits locally
      allowedSigners = ''
        ${email} namespaces="git" ${sshPublicKey}
      '';
    };
    settings = {
      alias = {
        st = "status -sb";
        fo = "fetch origin";
        d = "!git --no-pager diff";
        dt = "difftool";
        stat = "!git --no-pager diff --stat";

        # list stashes that were made on current branch
        # caveat: if current branch is substring of another branch, stashes from other branch are also matched
        gstlcb = "!git stash list --grep=\"$(git rev-parse --abbrev-ref HEAD)\"";

        # display list of tags with information about ref, author, subject
        taglist = "!git for-each-ref --format='%(refname:short) %(objectname:short) %(authordate:short) %(contents:subject)' refs/tags";

        # Set remotes/origin/HEAD -> defaultBranch (copied from https://stackoverflow.com/a/67672350/14870317)
        remoteSetHead = "remote set-head origin --auto";

        # Get default branch name (copied from https://stackoverflow.com/a/67672350/14870317)
        defaultBranch = "!git symbolic-ref refs/remotes/origin/HEAD | cut -d'/' -f4";

        # Clean merged branches (adapted from https://stackoverflow.com/a/6127884/14870317)
        sweep = "!git branch --merged $(git defaultBranch) | grep -E -v ' $(git defaultBranch)$' | xargs -r git branch -d && git remote prune origin";

        # http://www.jukie.net/bart/blog/pimping-out-git-log
        lg = "log --graph --all --pretty=format:'%Cred%h%Creset - %s %Cgreen(%cr) %C(bold blue)%an%Creset %C(yellow)%d%Creset'";

        # Serve local repo. http://coderwall.com/p/eybtga
        # Then other can access via `git clone git://#{YOUR_IP_ADDRESS}/
        serve = "!git daemon --reuseaddr --verbose  --base-path=. --export-all ./.git";

        # Checkout to defaultBranch
        m = "!git checkout $(git defaultBranch)";

        # Removes a file from the index
        unstage = "reset HEAD --";
      };

      branch = {
        master = {
          mergeoptions = "--no-edit";
        };
        main = {
          mergeoptions = "--no-edit";
        };
      };

      color = {
        branch = {
          current = "green";
          remote = "yellow";
        };
        diff = "auto";
        interactive = "auto";
        status = true;
        ui = true;
      };

      core = {
        editor = "zeditor --wait";
        pager = "less -FRSX";
      };

      help = {
        autocorrect = "prompt";
      };

      init = {
        defaultBranch = "main";
      };

      pull = {
        rebase = "true";
      };

      push = {
        default = "simple";
        autoSetupRemote = true;
      };

      rerere = {
        enabled = true;
      };

      user = {
        name = "Martin Klapper";
        inherit email;
      };
    };
  };

  programs.gh = {
    enable = true;
    extensions = with pkgs; [
      gh-dash
      gh-eco
    ];
    gitCredentialHelper = {
      enable = true;
      hosts = [ "https://github.com" ];
    };
  };

  # The key's passphrase lives in the keychain (UseKeychain in ~/.ssh/config), but
  # the agent starts empty after login; without this, signing fails until the first ssh.
  launchd.agents.ssh-add-keychain = {
    enable = true;
    config = {
      ProgramArguments = [
        "/usr/bin/ssh-add"
        "--apple-load-keychain"
        "-q"
      ];
      RunAtLoad = true;
    };
  };
}
