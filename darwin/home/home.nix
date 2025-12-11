{
  pkgs,
  config,
  ...
}:
{
  home = {
    homeDirectory = "/Users/martin";
    username = "martin";
    stateVersion = "25.05";

    # TODO: Sops
    # TODO: move dev-related packages into a dev-module and include for users
    packages = with pkgs; [
      _1password-cli
      age
      bc
      # bitwarden-cli
      bitwarden-desktop
      darwin.xcode_16
      discordo
      claude-code
      discord
      docker
      harlequin
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
      kitty
      meslo-lgs-nf
      mqttui
      mutt
      nixd
      nixfmt-rfc-style
      pinentry-tty
      rainfrog
      ripgrep
      raycast
      sbarlua
      shellcheck
      sketchybar-app-font
      tmux
      tmuxPlugins.tokyo-night-tmux
      tmuxPlugins.yank
      ttyper
      typtea
      postman
      obsidian
      opencode
      vscodium
      watchman
      yazi
      zed-editor
      zsh
      zsh-powerlevel10k
    ];

    sessionVariables = {
      TERMINAL = "kitty";
      EDITOR = "zeditor";
      # use fake omz cache dir for completions
      ZSH_CACHE_DIR = "${config.home.homeDirectory}/.cache/oh-my-zsh";
    };
  };

  programs = {
    home-manager.enable = true;

    bash = {
      enable = true;
    };

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

    firefox = {
      enable = true;
      languagePacks = [
        "en-US"
        "de"
      ];
      profiles = {
        martin = {
          id = 0;
          name = "martin";
          isDefault = true;
          # mostly taken from: https://github.com/gvolpe/nix-config
          settings = {
            "app.normandy.first_run" = false;
            "app.shield.optoutstudies.enabled" = false;

            "app.update.channel" = "default";

            "browser.contentblocking.category" = "strict"; # or standard
            "browser.ctrlTab.recentlyUsedOrder" = false;

            "browser.download.useDownloadDir" = true;
            "browser.download.viewableInternally.typeWasRegistered.svg" = true;
            "browser.download.viewableInternally.typeWasRegistered.webp" = true;
            "browser.download.viewableInternally.typeWasRegistered.xml" = true;

            "browser.link.open_newwindow" = true;

            "browser.search.region" = "CH";
            "browser.search.widget.inNavBar" = true;

            "browser.shell.checkDefaultBrowser" = false;
            "browser.search.defaultenginename" = "Kagi Search";
            "browser.search.order.1" = "Kagi Search";
            "browser.startup.homepage" = "https://kagi.com";
            "browser.tabs.loadInBackground" = true;
            "browser.urlbar.placeholderName" = "Kagi";
            "browser.urlbar.showSearchSuggestionsFirst" = false;

            "browser.urlbar.quickactions.enabled" = false;
            "browser.urlbar.quickactions.showPrefs" = false;
            "browser.urlbar.shortcuts.quickactions" = true;
            "browser.urlbar.suggest.quickactions" = false;

            "distribution.searchplugins.defaultLocale" = "en-US";

            # "doh-rollout.balrog-migration-done" = true; DNS over HTTPS
            # "doh-rollout.doneFirstRun" = true;

            "dom.forms.autocomplete.formautofill" = false;

            "general.autoScroll" = true;
            "general.useragent.locale" = "en-US";

            # firefox tokyo night
            "extensions.activeThemeID" = "{4520dc08-80f4-4b2e-982a-c17af42e5e4d}";
            "extensions.extensions.activeThemeID" = "{4520dc08-80f4-4b2e-982a-c17af42e5e4d}";

            "extensions.update.enabled" = false;
            "extensions.webcompat.enable_picture_in_picture_overrides" = true;
            "extensions.webcompat.enable_shims" = true;
            "extensions.webcompat.perform_injections" = true;
            "extensions.webcompat.perform_ua_overrides" = true;

            "privacy.donottrackheader.enabled" = true;

            # hardware key auth settings
            # "security.webauth.u2f" = true;
            # "security.webauth.webauthn" = true;
            # "security.webauth.webauthn_enable_softtoken" = true;
            # "security.webauth.webauthn_enable_usbtoken" = true;

            "accessibility.force_disabled" = 1;

            # disable Normandy/Shield
            "app.normandy.api_url" = "";
            "app.normandy.enabled" = false;

            # personalized Extension Recommendations in about:addons and AMO [FF65+]
            # https://support.mozilla.org/kb/personalized-extension-recommendations
            "browser.discovery.enabled" = false;
            "browser.helperApps.deleteTempFileOnExit" = true;

            "browser.newtabpage.activity-stream.default.sites" = "";
            "browser.newtabpage.activity-stream.feeds.topsites" = false;
            "browser.newtabpage.activity-stream.showSponsored" = false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
            "browser.uitour.enabled" = false;

            # use Mozilla geolocation service instead of Google.
            #"geo.provider.network.url"= "https://location.services.mozilla.com/v1/geolocate?key=%MOZILLA_API_KEY%";
            # disable using the OS's geolocation service
            "geo.provider.use_gpsd" = false;
            "geo.provider.use_geoclue" = false;

            # HIDDEN PREF: disable recommendation pane in about:addons
            "extensions.getAddons.showPane" = false;
            # recommendations in about:addons' Extensions and Themes panes [FF68+]
            "extensions.htmlaboutaddons.recommendations.enabled" = false;

            # disable Network Connectivity checks
            "network.connectivity-service.enabled" = false;

            # integrated calculator
            "browser.urlbar.suggest.calculator" = true;

            # TELEMETRY
            # disable new data submission
            "datareporting.policy.dataSubmissionEnabled" = false;
            # disable Health Reports
            "datareporting.healthreport.uploadEnabled" = false;
            # 0332: disable telemetry
            "toolkit.telemetry.unified" = false;
            "toolkit.telemetry.enabled" = false;
            "toolkit.telemetry.server" = "data:,";
            "toolkit.telemetry.archive.enabled" = false;
            "toolkit.telemetry.newProfilePing.enabled" = false;
            "toolkit.telemetry.shutdownPingSender.enabled" = false;
            "toolkit.telemetry.updatePing.enabled" = false;
            "toolkit.telemetry.bhrPing.enabled" = false;
            "toolkit.telemetry.firstShutdownPing.enabled" = false;
            # disable Telemetry Coverage
            "toolkit.telemetry.coverage.opt-out" = true; # [HIDDEN PREF]
            "toolkit.coverage.opt-out" = true; # [FF64+] [HIDDEN PREF]
            "toolkit.coverage.endpoint.base" = "";
            # disable PingCentre telemetry
            "browser.ping-centre.telemetry" = false;
            # disable Firefox Home (Activity Stream) telemetry
            "browser.newtabpage.activity-stream.feeds.telemetry" = false;
            "browser.newtabpage.activity-stream.telemetry" = false;
            "toolkit.telemetry.reportingpolicy.firstRun" = false;
            "toolkit.telemetry.shutdownPingSender.enabledFirstsession" = false;
            "browser.vpn_promo.enabled" = false;
          };

          search = {
            force = true;
            default = "Kagi Search";
            order = [
              "Kagi Search"
              "ddg"
              "google"
            ];
            engines = {
              "Kagi Search" = {
                urls = [
                  {
                    # TODO: Use kagi session token when sops is set up
                    # TODO: Aliases for lenses
                    template = "https://kagi.com/search?q={searchTerms}";
                  }
                ];
                icon = "https://assets.kagi.com/v2/favicon-32x32.png";
                definedAliases = [ "@ks" ];
              };
              "Nix Packages" = {
                urls = [
                  {
                    template = "https://search.nixos.org/packages";
                    params = [
                      {
                        name = "type";
                        value = "packages";
                      }
                      {
                        name = "channel";
                        value = "unstable";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = [ "@np" ];
              };
              "NixOS Wiki" = {
                urls = [ { template = "https://nixos.wiki/index.php?search={searchTerms}"; } ];
                icon = "https://nixos.wiki/favicon.png";
                updateInterval = 24 * 60 * 60 * 1000;
                definedAliases = [ "@nw" ];
              };
              "MyNixOS" = {
                urls = [ { template = "https://mynixos.com/search?q={searchTerms}"; } ];
                icon = "https://mynixos.com/favicon-32x32.png";
                updateInterval = 24 * 60 * 60 * 1000;
                definedAliases = [ "@nc" ];
              };
              "Nixhub.io" = {
                urls = [ { template = "https://nixhub.io/search?q={searchTerms}"; } ];
                icon = "https://www.nixhub.io/favicon.ico";
                updateInterval = 24 * 60 * 60 * 1000;
                definedAliases = [ "@nh" ];
              };
              "ddg".metaData.alis = "@d";
              "bing".metaData.hidden = true;
              "google".metaData.alias = "@g";
            };
          };

          # TODO: Persist extension configs separately
          extensions = {
            packages = with pkgs.nur.repos.rycee.firefox-addons; [
              bitwarden
              canvasblocker
              darkreader
              dearrow
              decentraleyes
              onepassword-password-manager
              privacy-badger
              react-devtools
              reduxdevtools
              sponsorblock
              tokyo-night-v2
              ublock-origin
              user-agent-string-switcher
              unpaywall
              to-deepl
              link-cleaner
              youtube-recommended-videos
              # epub-reader
              # gql network inspector
            ];
            # TODO: Extension settings
          };
        };
      };
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      # tmux.enableShellIntegrationOptions = [];
      # TODO: fzf history settings
    };

    git = {
      enable = true;
      signing = {
        key = null;
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
          gstlcb = "!git stash list --grep='$(git rev-parse --abbrev-ref HEAD)'";

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
          autocorrect = 1;
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
          email = "64156820+klappermartin@users.noreply.github.com";
        };
      };

      includes = [
        {
          path = "~/code/ax/.gitconfig";
          condition = "gitdir:~/code/ax/";
        }
      ];
    };

    gh = {
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

    gpg = {
      enable = true;
    };

    kitty = with pkgs; {
      enable = true;
      extraConfig = ''
        # fake tokyo night style theme
        background #222436
        foreground #c8d3f5
        selection_background #2d3f76
        selection_foreground #c8d3f5
        url_color #4fd6be
        cursor #c8d3f5
        cursor_text_color #222436

        active_tab_background #82aaff
        active_tab_foreground #1e2030
        inactive_tab_background #2f334d
        inactive_tab_foreground #545c7e
        tab_bar_background #1b1d2b

        active_border_color #82aaff
        inactive_border_color #2f334d

        color0 #1b1d2b
        color1 #ff757f
        color2 #c3e88d
        color3 #ffc777
        color4 #82aaff
        color5 #c099ff
        color6 #86e1fc
        color7 #828bb8

        color8 #444a73
        color9 #ff757f
        color10 #c3e88d
        color11 #ffc777
        color12 #82aaff
        color13 #c099ff
        color14 #86e1fc
        color15 #c8d3f5

        color16 #ff966c
        color17 #c53b53

        # Nerd Fonts v3.2.0
        symbol_map U+e000-U+e00a,U+ea60-U+ebeb,U+e0a0-U+e0c8,U+e0ca,U+e0cc-U+e0d7,U+e200-U+e2a9,U+e300-U+e3e3,U+e5fa-U+e6b1,U+e700-U+e7c5,U+ed00-U+efc1,U+f000-U+f2ff,U+f000-U+f2e0,U+f300-U+f372,U+f400-U+f533,U+f0001-U+f1af0 Symbols Nerd Font Mono
      '';

      font = {
        name = "MesloLGS NF";
        package = meslo-lgs-nf;
        size = 11;
      };
      settings = {
        hide_window_decorations = "titlebar-only";
        window_margin_width = 4;
        placement_strategy = "center";
      };
      shellIntegration.enableZshIntegration = true;
    };

    lsd = {
      enable = true;
      enableZshIntegration = true;
      # TODO: Custom colors and icons
    };

    neovim = {
      enable = true;
      vimAlias = true;
    };

    pay-respects = {
      enable = true;
      enableZshIntegration = true;
    };

    tmux = {
      enable = true;

      baseIndex = 1;
      extraConfig = ''
        # Allow x-keys (like C-left to move by full word)
        set-option -g xterm-keys on

        # use vi key in copy mode
        setw -g mode-keys vi

        # bind ctrl + Arrowkeys to navigate in cli
        bind -n M-Left send-keys M-b
        bind -n M-Right send-keys M-f

        # bind pane-sync to ctrl + b + g
        bind C-g set-window-option synchronize-panes

        # Temporarily re-set the shell var for use with tmux sensibleOnTop
        # see: https://github.com/nix-community/home-manager/issues/5952
        set -gu default-command
        set -g default-shell "$SHELL"
      '';
      clock24 = true;
      mouse = true;
      plugins = with pkgs; [
        {
          plugin = tmuxPlugins.tokyo-night-tmux;
          extraConfig = ''
            # common macOS L; no unicode support
            set -g @tokyo-night-tmux_window_id_style none
          '';
        }
        tmuxPlugins.yank
      ];
      shell = "${pkgs.zsh}/bin/zsh";
      terminal = "screen-256color";
      tmuxinator.enable = true;
    };

    # TODO: Don't search for updates.
    vscode = with pkgs; {
      enable = true;
      package = vscodium;

      # TODO: Fix the extension change conflicts when mutable dir is enabled
      mutableExtensionsDir = false;

      profiles = {
        default = {
          # can only be set here but applies to all profiles
          enableUpdateCheck = false;
          enableExtensionUpdateCheck = false;

          # TODO: and/or move to extensions module in e.g. /home/vscode
          extensions =
            with pkgs.vscode-extensions;
            with pkgs.vscode-utils;
            [
              # nix
              bbenoist.nix
              brettm12345.nixfmt-vscode

              # md
              yzhang.markdown-all-in-one
              unifiedjs.vscode-mdx

              # yaml
              redhat.vscode-yaml

              # python
              # ms-python.python
              ms-python.vscode-pylance
              charliermarsh.ruff

              batisteo.vscode-django

              # golang
              golang.go

              # TODO: Re-enable when updated to sha match
              # rust
              # rust-lang.rust-analyzer

              # gql
              graphql.vscode-graphql
              graphql.vscode-graphql-syntax

              # js/ts
              christian-kohler.npm-intellisense
              yoavbls.pretty-ts-errors

              # html/css
              bradlc.vscode-tailwindcss
              formulahendry.auto-close-tag
              formulahendry.auto-rename-tag
              vincaslt.highlight-matching-tag
              naumovs.color-highlight

              # format
              dbaeumer.vscode-eslint
              esbenp.prettier-vscode

              # git / github
              eamodio.gitlens

              github.vscode-github-actions
              github.vscode-pull-request-github

              # other
              christian-kohler.path-intellisense
              emmanuelbeziat.vscode-great-icons
              firefox-devtools.vscode-firefox-debug
              mikestead.dotenv
              wix.vscode-import-cost
              usernamehw.errorlens
              streetsidesoftware.code-spell-checker
              shardulm94.trailing-spaces
              aaron-bond.better-comments
            ]
            ++ extensionsFromVscodeMarketplace [
              {
                name = "sqltools";
                publisher = "mtxr";
                version = "latest";
                sha256 = "sha256-2JgBRMaNU3einOZ0POfcc887HCScu6myETTLoJMS6o8=";
              }
              {
                name = "rust-analyzer";
                publisher = "rust-lang";
                version = "latest";
                sha256 = "sha256-HwELyT9Rq96w90IvAXB4u0EUvd0D7HArWuKtYeaOOKs=";
              }
              {
                name = "oxc-vscode";
                publisher = "oxc";
                version = "latest";
                sha256 = "sha256-Vabz0/NDhh09nxFSRqGk+/eRVCNXw6sOrSu9qIm9j9A=";
              }
              {
                name = "python";
                publisher = "ms-python";
                version = "latest";
                sha256 = "sha256-f573A/7s8jVfH1f3ZYZSTftrfBs6iyMWewhorX4Z0Nc=";
              }
              {
                name = "playwright";
                publisher = "ms-playwright";
                version = "latest";
                sha256 = "sha256-t5PJtBDkjh80IhOpfjsX8kZCSfhGoQ1dePEYMYgw66c=";
              }
              {
                name = "code-spell-checker-british-english";
                publisher = "streetsidesoftware";
                version = "latest";
                sha256 = "sha256-j/XdeswdXWnkY/LhDwkdkFmn2sICSRnAHcUCoGPlPGc=";
              }
              {
                name = "code-spell-checker-german";
                publisher = "streetsidesoftware";
                version = "latest";
                sha256 = "sha256-40Oc6ycNog9cxG4G5gCps2ADrM/wLuKWFrD4lnd91Z4=";
              }
              {
                name = "vscode-todo-highlight";
                publisher = "wayou";
                version = "latest";
                sha256 = "sha256-CQVtMdt/fZcNIbH/KybJixnLqCsz5iF1U0k+GfL65Ok=";
              }
              {
                name = "tokyo-night-moon";
                publisher = "patricknasralla";
                version = "latest";
                sha256 = "sha256-8rUbsDCk7JHSN4vn+TNTmIrx8ma53hH/1x0trqDwU7Y=";
              }
              {
                name = "vscode-css-peek";
                publisher = "pranaygp";
                version = "latest";
                sha256 = "sha256-oY+mpDv2OTy5hFEk2DMNHi9epFm4Ay4qi0drCXPuYhU=";
              }
              {
                name = "cucumberautocomplete";
                publisher = "alexkrechik";
                version = "latest";
                sha256 = "sha256-Tgqd4uoVgGJQKlj4JUM1CrjQhbi0qv9bAGz5NIHyofQ=";
              }
              {
                name = "language-gettext";
                publisher = "mrorz";
                version = "latest";
                sha256 = "sha256-1hdT2Fai0o48ojNqsjW+McokD9Nzt2By3vzhGUtgaeA=";
              }
              {
                name = "vscode-typescript-next";
                publisher = "ms-vscode";
                version = "latest";
                sha256 = "sha256-6xsmmMfd9XppkvuEp5vWoTLvlRTH74t37+8ZPVmSsx4=";
              }
              {
                name = "react-proptypes-intellisense";
                publisher = "ofhumanbondage";
                version = "latest";
                sha256 = "sha256-lmAjqOR+rznx5Q7W/ChRg8sb1NhqN2YtrwRn8zHYtRo=";
              }
              {
                name = "shellcheck";
                publisher = "timonwong";
                version = "latest";
                sha256 = "sha256-JSS0GY76+C5xmkQ0PNjt2Nu/uTUkfiUqmPL51r64tl0=";
              }
              {
                name = "vscode-expo-tools";
                publisher = "expo";
                version = "latest";
                sha256 = "sha256-qNgidCb8D13coJkykgwViSuMNxXaqitkN3VRKLS3LWk=";
              }
            ];

          keybindings = [
            {
              key = "alt+control+right";
              command = "cursorWordPartRight";
              when = "editorTextFocus";
            }
            {
              key = "alt+control+left";
              command = "cursorWordPartLeft";
              when = "editorTextFocus";
            }
            {
              key = "alt+control+shitft+left";
              command = "cursorWordPartLeftSelect";
              when = "editorTextFocus";
            }
            {
              key = "alt+control+shitft+right";
              command = "cursorWordPartRightSelect";
              when = "editorTextFocus";
            }
          ];

          userSettings = {
            # Python specific settings
            "[python]" = {
              "editor.bracketPairColorization.enabled" = false;
              "editor.guides.bracketPairs" = true;
              "editor.tabSize" = 4;
              "editor.defaultFormatter" = "charliermarsh.ruff";
              "editor.formatOnSave" = true;
              "diffEditor.ignoreTrimWhitespace" = true;
            };

            "[nix]" = {
              "editor.defaultFormatter" = "brettm12345.nixfmt-vscode";
            };

            "[sql]" = {
              "editor.defaultFormatter" = "mtxr.sqltools";
            };

            # General editor settings
            "editor.bracketPairColorization.enabled" = true;
            "editor.cursorStyle" = "block";
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
            "editor.detectIndentation" = false;
            "editor.fontSize" = 14;
            "editor.formatOnSave" = true;
            "editor.gotoLocation.multipleDefinitions" = "gotoAndPeek";
            "editor.guides.bracketPairs" = true;
            "editor.minimap.enabled" = false;
            "editor.multiCursorModifier" = "ctrlCmd";
            "editor.renderControlCharacters" = true;
            "editor.rulers" = [
              80
              120
            ];
            "editor.showFoldingControls" = "always";
            "editor.snippetSuggestions" = "top";
            "editor.tabSize" = 2;
            "emmet.includeLanguages" = {
              "erb" = "html";
            };
            "editor.codeActionsOnSave" = {
              "source.fixAll" = "explicit";
            };
            "editor.quickSuggestions" = {
              "other" = "on";
              "comments" = "off";
              "strings" = "on";
            };
            "emmet.showSuggestionsAsSnippets" = true;
            "emmet.triggerExpansionOnTab" = true;
            "explorer.confirmDelete" = false;

            # File settings
            "files.associations" = {
              ".css" = "tailwindcss";
            };
            "files.exclude" = {
              "__pycache__" = true;
              "_site" = true;
              ".asset-cache" = true;
              ".bundle" = true;
              ".ipynb_checkpoints" = true;
              ".pytest_cache" = true;
              ".sass-cache" = true;
              ".svn" = true;
              "**/.DS_Store" = true;
              "**/.egg-info" = true;
              "**/.git" = true;
              "build" = true;
              "coverage" = true;
              "dist" = true;
              "log" = true;
              "node_modules" = false;
              "public/packs" = true;
              "tmp" = true;
            };
            "files.hotExit" = "off";
            "files.insertFinalNewline" = true;
            "files.trimFinalNewlines" = true;
            "files.trimTrailingWhitespace" = true;
            "files.watcherExclude" = {
              "**/audits/**" = true;
              "**/coverage/**" = true;
              "**/log/**" = true;
              "**/node_modules/**" = true;
              "**/tmp/**" = true;
              "**/vendor/**" = true;
            };

            # Notebook settings
            "notebook.diff.ignoreMetadata" = true;
            "notebook.lineNumbers" = "on";
            "notebook.markup.fontSize" = 13;

            # Python settings
            "python.analysis.typeCheckingMode" = "basic";
            "python.analysis.autoImportCompletions" = true;
            "python.languageServer" = "Jedi";
            "python.terminal.activateEnvironment" = false;

            # Tailwind CSS settings
            "tailwindCSS.experimental.classRegex" = [
              [
                "cva\\(([^)]*)\\)"
                "[\"'`]([^\"'`]*).*?[\"'`]"
              ]
              [
                "cx\\(([^)]*)\\)"
                "(?:'|\"|`)([^']*)(?:'|\"|`)"
              ]
            ];

            # Window settings
            "window.restoreWindows" = "none";
            "window.newWindowDimensions" = "maximized";
            "window.zoomLevel" = -1;

            # Workbench settings
            "workbench.editor.enablePreview" = true;
            "workbench.settings.editor" = "json";
            "workbench.settings.openDefaultSettings" = false;
            "workbench.settings.useSplitJSON" = true;
            "workbench.startupEditor" = "newUntitledFile";
            "workbench.panel.defaultLocation" = "bottom";
            "security.workspace.trust.untrustedFiles" = "open";
            "workbench.sideBar.location" = "right";
            "workbench.colorTheme" = "Tokyo Night Moon";
            "workbench.iconTheme" = "vscode-great-icons";

            # Accessibility support
            "editor.accessibilitySupport" = "off";

            # Spell check settings
            "cSpell.language" = "en,de-DE,en-GB,en-US,de";

            # TypeScript settings
            "typescript.updateImportsOnFileMove.enabled" = "always";
            "typescript.preferences.importModuleSpecifier" = "non-relative";

            # Playwright settings
            "playwright.reuseBrowser" = true;

            # GitHub settings
            "githubPullRequests.pullBranch" = "never";
            "go.toolsManagement.autoUpdate" = true;
            "git.openRepositoryInParentFolders" = "always";

            # Terminal settings
            "terminal.external.osxExec" = "kitty.app";

            # Editor associations
            "workbench.editorAssociations" = {
              "git-rebase-todo" = "default";
            };

            # Diff editor settings
            "diffEditor.ignoreTrimWhitespace" = false;

            # Makefile settings
            "makefile.configureOnOpen" = true;
          };
        };
      };
    };

    zsh = {
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
          omzPlugins = fetchFromGitHub {
            owner = "ohmyzsh";
            repo = "ohmyzsh";
            rev = "master";
            sha256 = "sha256-rI673tQ3W4U9N5i8LZx9dpKzft7+Y0UZ7iTSJwnoSSE=";
          };
        in
        [
          {
            name = "zsh-powerlevel10k";
            src = "${zsh-powerlevel10k}/share/zsh-powerlevel10k/";
            file = "powerlevel10k.zsh-theme";
          }
          {
            name = "zsh-you-should-use";
            src = fetchFromGitHub {
              owner = "MichaelAquilina";
              repo = "zsh-you-should-use";
              rev = "1.9.0";
              sha256 = "sha256-+3iAmWXSsc4OhFZqAMTwOL7AAHBp5ZtGGtvqCnEOYc0=";
            };
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
        # TODO: don't use system python
        speedtest = "curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -";

        pn = "pnpm";
      };
      # TODO: History options
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };
  services = {
    gpg-agent = {
      enable = true;
      enableZshIntegration = true;
      defaultCacheTtl = 21600; # 6 hours
      maxCacheTtl = 86400; # 1 day
      pinentry.package = pkgs.pinentry-tty;
    };

    jankyborders = {
      enable = true;
      package = pkgs.jankyborders;
      settings = {
        style = "round";
        width = 1.0;
        hidpi = "on";
        active_color = "0xc0e2e2e3";
        inactive_color = "0xc02c2e34";
        background_color = "0x302c2e34";
      };
    };

    skhd = {
      enable = true;
      package = pkgs.skhd;
      # Copied from https://github.com/FelixKratz/dotfiles/blob/master/.config/skhd/skhdrc
      config = ''
        ## Navigation (lalt - ...)
        # Space Navigation (four spaces per display): lalt - {1, 2, 3, 4}
        lalt - 1 : SPACES=($(yabai -m query --displays --display | jq '.spaces[]')) && [[ -n $SPACES[1] ]] && yabai -m space --focus $SPACES[1]
        lalt - 2 : SPACES=($(yabai -m query --displays --display | jq '.spaces[]')) && [[ -n $SPACES[2] ]] && yabai -m space --focus $SPACES[2]
        lalt - 3 : SPACES=($(yabai -m query --displays --display | jq '.spaces[]')) && [[ -n $SPACES[3] ]] && yabai -m space --focus $SPACES[3]
        lalt - 4 : SPACES=($(yabai -m query --displays --display | jq '.spaces[]')) && [[ -n $SPACES[4] ]] && yabai -m space --focus $SPACES[4]

        ralt - 1 : SPACES=($(yabai -m query --displays --display | jq '.spaces[]')) && [[ -n $SPACES[1] ]] && yabai -m space --focus $SPACES[1]
        ralt - 2 : SPACES=($(yabai -m query --displays --display | jq '.spaces[]')) && [[ -n $SPACES[2] ]] && yabai -m space --focus $SPACES[2]
        ralt - 3 : SPACES=($(yabai -m query --displays --display | jq '.spaces[]')) && [[ -n $SPACES[3] ]] && yabai -m space --focus $SPACES[3]
        ralt - 4 : SPACES=($(yabai -m query --displays --display | jq '.spaces[]')) && [[ -n $SPACES[4] ]] && yabai -m space --focus $SPACES[4]

        # Window Navigation (through display borders): lalt - {h, j, k, ;}
        lalt - h    : yabai -m window --focus west  || yabai -m display --focus west
        lalt - j    : yabai -m window --focus south || yabai -m display --focus south
        lalt - k    : yabai -m window --focus north || yabai -m display --focus north
        lalt - l    : yabai -m window --focus east  || yabai -m display --focus east

        # Extended Window Navigation: lalt - {;, '}
        lalt - 0x29 : yabai -m window --focus first
        lalt - 0x27 : yabai -m window --focus  last

        # Float / Unfloat window: lalt - space
        lalt - space : yabai -m window --toggle float

        # Make window zoom to fullscreen: shift + lalt - f
        shift + lalt - f : yabai -m window --toggle zoom-fullscreen

        # Make window zoom to parent node: lalt - f
        lalt - f : yabai -m window --toggle zoom-parent

        ## Window Movement (shift + lalt - ...)
        # Moving windows in spaces: shift + lalt - {j, k, l, ;}
        shift + lalt - h : yabai -m window --warp west || $(yabai -m window --display west && yabai -m display --focus west && yabai -m window --warp last) || yabai -m window --move rel:-10:0
        shift + lalt - j : yabai -m window --warp south || $(yabai -m window --display south && yabai -m display --focus south) || yabai -m window --move rel:0:10
        shift + lalt - k : yabai -m window --warp north || $(yabai -m window --display north && yabai -m display --focus north) || yabai -m window --move rel:0:-10
        shift + lalt - l : yabai -m window --warp east || $(yabai -m window --display east && yabai -m display --focus east && yabai -m window --warp first) || yabai -m window --move rel:10:0

        # Toggle split orientation of the selected windows node: shift + lalt - s
        shift + lalt - s : yabai -m window --toggle split

        # Moving windows between spaces: shift + lalt - {1, 2, 3, 4, p, n } (Assumes 4 Spaces Max per Display)
        shift + lalt - 1 : SPACES=($(yabai -m query --displays --display | jq '.spaces[]')) && [[ -n $SPACES[1] ]] \
                          && yabai -m window --space $SPACES[1]

        shift + lalt - 2 : SPACES=($(yabai -m query --displays --display | jq '.spaces[]')) && [[ -n $SPACES[2] ]] \
                          && yabai -m window --space $SPACES[2]

        shift + lalt - 3 : SPACES=($(yabai -m query --displays --display | jq '.spaces[]')) && [[ -n $SPACES[3] ]] \
                          && yabai -m window --space $SPACES[3]

        shift + lalt - 4 : SPACES=($(yabai -m query --displays --display | jq '.spaces[]')) && [[ -n $SPACES[4] ]] \
                          && yabai -m window --space $SPACES[4]

        shift + ralt - 1 : SPACES=($(yabai -m query --displays --display | jq '.spaces[]')) && [[ -n $SPACES[1] ]] \
                         && yabai -m window --space $SPACES[1]

        shift + ralt - 2 : SPACES=($(yabai -m query --displays --display | jq '.spaces[]')) && [[ -n $SPACES[2] ]] \
                         && yabai -m window --space $SPACES[2]

        shift + ralt - 3 : SPACES=($(yabai -m query --displays --display | jq '.spaces[]')) && [[ -n $SPACES[3] ]] \
                         && yabai -m window --space $SPACES[3]

        shift + ralt - 4 : SPACES=($(yabai -m query --displays --display | jq '.spaces[]')) && [[ -n $SPACES[4] ]] \
                          && yabai -m window --space $SPACES[4]

        shift + lalt - p : yabai -m window --space prev && yabai -m space --focus prev
        shift + lalt - n : yabai -m window --space next && yabai -m space --focus next

        # Mirror Space on X and Y Axis: shift + lalt - {x, y}
        shift + lalt - x : yabai -m space --mirror x-axis
        shift + lalt - y : yabai -m space --mirror y-axis

        ## Stacks (shift + ctrl - ...)
        # Add the active window to the window or stack to the {direction}: shift + ctrl - {h, j, k, ;}
        shift + ctrl - h    : yabai -m window  west --stack $(yabai -m query --windows --window | jq -r '.id')
        shift + ctrl - j    : yabai -m window south --stack $(yabai -m query --windows --window | jq -r '.id')
        shift + ctrl - k    : yabai -m window north --stack $(yabai -m query --windows --window | jq -r '.id')
        shift + ctrl - l    : yabai -m window  east --stack $(yabai -m query --windows --window | jq -r '.id')

        # Stack Navigation: shift + ctrl - {n, p}
        shift + ctrl - n : yabai -m window --focus stack.next
        shift + ctrl - p : yabai -m window --focus stack.prev

        ## Resize (ctrl + lalt - ...)
        # Resize windows: ctrl + lalt - {h, j, k, ;}
        ctrl + lalt - h    : yabai -m window --resize right:-100:0 || yabai -m window --resize left:-100:0
        ctrl + lalt - j    : yabai -m window --resize bottom:0:100 || yabai -m window --resize top:0:100
        ctrl + lalt - k    : yabai -m window --resize bottom:0:-100 || yabai -m window --resize top:0:-100
        ctrl + lalt - l    : yabai -m window --resize right:100:0 || yabai -m window --resize left:100:0

        # Equalize size of windows: ctrl + lalt - e
        ctrl + lalt - e : yabai -m space --balance

        # Enable / Disable gaps in current workspace: ctrl + lalt - g
        ctrl + lalt - g : yabai -m space --toggle padding; yabai -m space --toggle gap

        ## Insertion (shift + ctrl + lalt - ...)
        # Set insertion point for focused container: shift + ctrl + lalt - {h, j, k, ;, s}
        shift + ctrl + lalt - h : yabai -m window --insert west
        shift + ctrl + lalt - j : yabai -m window --insert south
        shift + ctrl + lalt - k : yabai -m window --insert north
        shift + ctrl + lalt - l : yabai -m window --insert east
        shift + ctrl + lalt - s : yabai -m window --insert stack

        # New window in hor./ vert. splits for all applications with yabai
        lalt - s : yabai -m window --insert east;  skhd -k "cmd - n"
        lalt - v : ya4bai -m window --insert south; skhd -k "cmd - n"

        # Toggle sketchybar
        shift + lalt - space : sketchybar --bar hidden=toggle
      '';
    };
  };
}
