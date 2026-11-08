{
  config,
  lib,
  pkgs,
  ...
}:
let
  # The M2 keeps its existing Anthropic authentication flow. The company M5
  # explicitly removes this plugin in modules/darwin/home/company-opencode.nix.
  anthropicAuthPluginV2 = "@ex-machina/opencode-anthropic-auth@2.0.0-next.5";
  # Projects opt in by command name; keep the Darwin app path and version-specific
  # flags here so every project uses the same configured browser.
  firefoxMcp = pkgs.writeShellApplication {
    name = "firefox-devtools-mcp";
    text = ''
      exec ${lib.getExe pkgs.firefox-devtools-mcp} \
        --firefox-path ${lib.escapeShellArg "${config.programs.firefox.package}/Applications/Firefox Developer Edition.app/Contents/MacOS/firefox-devedition"} \
        --enable-script --start-url about:blank "$@"
    '';
  };

  # Follow nixpkgs while retaining the privacy environment used by the MCP.
  codegraph = pkgs.writeShellApplication {
    name = "codegraph";
    runtimeEnv = {
      CODEGRAPH_TELEMETRY = "0";
      DO_NOT_TRACK = "1";
    };
    text = ''exec ${lib.getExe pkgs.codegraph} "$@"'';
  };

  # Use the nixpkgs package so OpenCode follows the flake's nixpkgs revision.
  # The wrapper only makes project-opt-in MCP executables available to its
  # background service.
  opencode = pkgs.writeShellApplication {
    name = "opencode";
    runtimeInputs = [
      pkgs.ripgrep
      pkgs.mcp-nixos
      firefoxMcp
    ];
    runtimeEnv = {
      OPENCODE_DISABLE_AUTOUPDATE = "1";
    };
    text = ''exec ${lib.getExe pkgs.opencode} "$@"'';
  };

  opencodeConfigDirectory = "${config.xdg.configHome}/opencode";
  lspTools = pkgs.writeShellApplication {
    name = "lsp-tools-mcp";
    # Nixpkgs supplies a fallback tsserver; workspace TypeScript takes precedence.
    runtimeInputs = [ pkgs.typescript-language-server ];
    runtimeEnv = {
      LSP_TOOLS_MCP_USER_CONFIG = "${opencodeConfigDirectory}/lsp.json";
      LSP_TOOLS_MCP_INSTALL_DECISIONS = "${opencodeConfigDirectory}/lsp-install-decisions.json";
      LSP_TOOLS_MCP_PROJECT_CONFIG = ".opencode/lsp.json";
    };
    text = ''
      exec ${pkgs.nodejs_22}/bin/node ${./vendor/lsp-tools-mcp/cli.mjs} "$@"
    '';
  };
in
{
  programs.opencode = {
    enable = true;
    package = opencode;
    settings = {
      plugins = [ anthropicAuthPluginV2 ];
      mcp.servers = {
        codegraph = {
          type = "local";
          command = [
            (lib.getExe codegraph)
            "serve"
            "--mcp"
          ];
        };
        context7 = {
          type = "remote";
          url = "https://mcp.context7.com/mcp";
        };
        linear = {
          type = "remote";
          url = "https://mcp.linear.app/mcp";
          oauth = { };
        };
        figma = {
          type = "remote";
          url = "http://127.0.0.1:3845/mcp";
        };
        grep_app = {
          type = "remote";
          url = "https://mcp.grep.app";
        };
        lsp = {
          type = "local";
          command = [ (lib.getExe lspTools) ];
        };
        websearch = {
          type = "remote";
          url = "https://mcp.exa.ai/mcp?tools=web_search_exa";
        };
      };
    };
    agents.librarian = ./agents/librarian.md;
    skills = {
      ast-grep = ./vendor/skills/ast-grep;
      data-scientist = ./vendor/skills/data-scientist;
      eval-integrity = ./vendor/skills/eval-integrity;
      git-master = ./vendor/skills/git-master;
      lsp-setup = ./vendor/skills/lsp-setup;
      oss-reference = ../../../../skills/oss-reference;
      playwright = ./skills/playwright;
      remove-ai-slops = ./vendor/skills/remove-ai-slops;
      security-review = ./vendor/skills/security-review;
      visual-qa = ./vendor/skills/visual-qa;
    };
  };

  xdg.configFile."opencode/commands/handoff.md".source = ./commands/handoff.md;

  home.packages = [
    codegraph
    lspTools
    pkgs.mcp-nixos
    firefoxMcp
    pkgs.typescript-language-server
  ];

  # HM removes the old managed profiles. Retire the mutable selection created by
  # the former switcher separately, preserving it rather than deleting user data.
  home.activation.retireOmoProfile =
    lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ]
      ''
        active=${lib.escapeShellArg "${config.home.homeDirectory}/.omo/omo.jsonc"}
        retired=${lib.escapeShellArg "${config.xdg.stateHome}/home-manager/retired-config"}
        if [[ -f "$active" || -L "$active" ]]; then
          run mkdir -p "$retired"
          if [[ -L "$active" && -f "$active" ]]; then
            # Save the selected contents before HM removes the old profile targets.
            run ${pkgs.coreutils}/bin/cp -L --backup=numbered -T -- "$active" "$retired/omo.jsonc"
            run rm -- "$active"
          else
            run ${pkgs.coreutils}/bin/mv --backup=numbered -T -- "$active" "$retired/omo.jsonc"
          fi
        fi
      '';
}
