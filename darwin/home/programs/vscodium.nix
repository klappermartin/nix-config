{
  pkgs,
  ...
}:
{
  programs.vscodium = {
    enable = true;

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
            ms-python.python
            ms-python.debugpy
            ms-python.vscode-pylance
            charliermarsh.ruff

            batisteo.vscode-django

            # golang
            golang.go

            # rust
            rust-lang.rust-analyzer

            # gql
            graphql.vscode-graphql
            graphql.vscode-graphql-syntax

            # js/ts
            christian-kohler.npm-intellisense
            yoavbls.pretty-ts-errors

            # html/css
            pranaygp.vscode-css-peek
            bradlc.vscode-tailwindcss
            formulahendry.auto-close-tag
            formulahendry.auto-rename-tag
            vincaslt.highlight-matching-tag
            naumovs.color-highlight

            # format
            oxc.oxc-vscode
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
            streetsidesoftware.code-spell-checker-german
            timonwong.shellcheck
            shardulm94.trailing-spaces
            aaron-bond.better-comments
          ]
          ++ extensionsFromVscodeMarketplace [
            {
              name = "sqltools";
              publisher = "mtxr";
              version = "0.28.6";
              sha256 = "sha256-SpVFH+Qf9tpnNm4J5z3fOhWzzYP0LknDNm88JHMxkIU=";
            }
            {
              name = "playwright";
              publisher = "ms-playwright";
              version = "1.1.20";
              sha256 = "sha256-6plefZcKexQaSgxEv5eaMWO+2bWWuwki1ml/ZEUCGbw=";
            }
            {
              name = "code-spell-checker-british-english";
              publisher = "streetsidesoftware";
              version = "2.0.1";
              sha256 = "sha256-CB2lxZlSOlY3E3hX0ZDOez8V5BPJeGYBUjhnLRxoMy4=";
            }
            {
              name = "vscode-todo-highlight";
              publisher = "wayou";
              version = "1.0.5";
              sha256 = "sha256-CQVtMdt/fZcNIbH/KybJixnLqCsz5iF1U0k+GfL65Ok=";
            }
            {
              name = "tokyo-night-moon";
              publisher = "patricknasralla";
              version = "1.1.4";
              sha256 = "sha256-8rUbsDCk7JHSN4vn+TNTmIrx8ma53hH/1x0trqDwU7Y=";
            }
            {
              name = "cucumberautocomplete";
              publisher = "alexkrechik";
              version = "3.1.1";
              sha256 = "sha256-0CYg+hb9XZlbTHLObA1JPfD/grJzVr9QN4EwwuX8bAI=";
            }
            {
              name = "language-gettext";
              publisher = "mrorz";
              version = "0.5.0";
              sha256 = "sha256-1hdT2Fai0o48ojNqsjW+McokD9Nzt2By3vzhGUtgaeA=";
            }
            {
              name = "vscode-typescript-next";
              publisher = "ms-vscode";
              version = "6.0.20260416";
              sha256 = "sha256-/lvP3a2IJ4PhwThvx0J8wDcch2te2Ezs8v0Lh9A5bpg=";
            }
            {
              name = "react-proptypes-intellisense";
              publisher = "ofhumanbondage";
              version = "1.0.3";
              sha256 = "sha256-lmAjqOR+rznx5Q7W/ChRg8sb1NhqN2YtrwRn8zHYtRo=";
            }
            {
              name = "vscode-expo-tools";
              publisher = "expo";
              version = "1.6.3";
              sha256 = "sha256-vqT/72pUyHtzl0rmUfDgbr7MO+/2dw3EcDeYTkQY/0Y=";
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
            key = "alt+control+shift+left";
            command = "cursorWordPartLeftSelect";
            when = "editorTextFocus";
          }
          {
            key = "alt+control+shift+right";
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
}
