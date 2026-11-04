{
  config,
  lib,
  pkgs,
  ...
}:
let
  gitHelper =
    name: source:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ pkgs.git ];
      text = builtins.readFile source;
    };
  defaultBranch = gitHelper "git-default-branch" ./git-default-branch.sh;
  sweep = gitHelper "git-sweep" ./git-sweep.sh;
  email = "64156820+klappermartin@users.noreply.github.com";
  sshKeyFile = config.workstation.ssh.keyFile;
in
{
  programs.git = {
    enable = true;
    includes = [
      {
        condition = "gitdir:~/code/work/";
        path = "work.conf";
      }
    ];
    signing = {
      format = "ssh";
      # must be added on GitHub as a *signing* key
      key = "${config.home.homeDirectory}/${sshKeyFile}.pub";
      signByDefault = true;
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

        # Preserve branch names containing slashes and fail if origin/HEAD is unset.
        defaultBranch = "!${defaultBranch}/bin/git-default-branch";

        # Preserve the default branch and every checked-out worktree branch.
        sweep = "!${sweep}/bin/git-sweep";

        # http://www.jukie.net/bart/blog/pimping-out-git-log
        lg = "log --graph --all --pretty=format:'%Cred%h%Creset - %s %Cgreen(%cr) %C(bold blue)%an%Creset %C(yellow)%d%Creset'";

        # Serve local repo. http://coderwall.com/p/eybtga
        # Then other can access via `git clone git://#{YOUR_IP_ADDRESS}/
        serve = "!git daemon --reuseaddr --verbose  --base-path=. --export-all ./.git";

        # Checkout to defaultBranch
        m = ''!f() { branch=$(git defaultBranch) || return; git checkout "$branch"; }; f'';

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

      # resolve to the per-machine file built by the home.activation step below,
      # so `git log --show-signature` can verify own commits locally
      "gpg.ssh" = {
        allowedSignersFile = "~/.config/git/allowed_signers";
      };

      user = {
        name = "Martin Klapper";
        inherit email;
      };
    };
  };

  # Generate allowed_signers on the machine itself: the public key of this
  # device lives outside the flake, so it cannot be read during (pure) eval.
  # Reading it here in the activation script keeps the repo key-free.
  # Let Home Manager remove the previously managed symlink first. Atomic
  # replacement also avoids following any leftover symlink into the Nix store.
  home.activation.allowedSigners = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${pkgs.writeShellScript "generate-git-allowed-signers" ''
      set -euo pipefail
      export PATH=${lib.makeBinPath [ pkgs.coreutils ]}
      key="$(cat ${lib.escapeShellArg "${config.home.homeDirectory}/${sshKeyFile}.pub"})"
      directory=${lib.escapeShellArg "${config.home.homeDirectory}/.config/git"}
      mkdir -p "$directory"
      temporary="$(mktemp "$directory/.allowed_signers.XXXXXX")"
      trap 'rm -f "$temporary"' EXIT
      printf '%s namespaces="git" %s\n' ${lib.escapeShellArg email} "$key" > "$temporary"
      chmod 600 "$temporary"
      mv -fT "$temporary" "$directory/allowed_signers"
    ''}
  '';

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
