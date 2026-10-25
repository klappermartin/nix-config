{
  config,
  lib,
  pkgs,
  ...
}:
let
  # The 2.x auth plugin targets OpenCode V2. Anthropic
  # gates models on the Claude Code version this plugin reports; on 400
  # `claude_code_version_too_old`, bump it or set `ANTHROPIC_CLAUDE_CODE_VERSION`.
  anthropicAuthPluginV2 = "@ex-machina/opencode-anthropic-auth@2.0.0-next.5";
  opencodeV2Version = "2.0.24";
  codegraphVersion = "1.6.2";

  # The main npm package is only a launcher; the runnable bundle ships per platform.
  codegraphBundle = pkgs.fetchzip {
    url = "https://registry.npmjs.org/@colbymchenry/codegraph-darwin-arm64/-/codegraph-darwin-arm64-${codegraphVersion}.tgz";
    hash = "sha256-d88aph8IJbcjcQGuJRV0PlIGyQ/hkaOJ6k8RRkILrq8=";
  };

  # CodeGraph has no global codegraph.json. Extend its built-in directory skips
  # for every project; node_modules is already excluded upstream.
  codegraphPatchedBundle = pkgs.runCommand "codegraph-${codegraphVersion}-bundle" { } ''
    cp -R ${codegraphBundle} "$out"
    chmod -R u+w "$out"
    substituteInPlace "$out/lib/dist/extraction/index.js" \
      --replace-fail "'.yarn', '.pnpm-store'," "'.yarn', '.pnpm-store', '.devenv', 'devenv',"
  '';

  codegraph = pkgs.writeShellApplication {
    name = "codegraph";
    runtimeEnv = {
      CODEGRAPH_TELEMETRY = "0";
      DO_NOT_TRACK = "1";
    };
    text = ''exec ${codegraphPatchedBundle}/bin/codegraph "$@"'';
  };

  # V2 ships signed per-platform binaries on npm; the pinned nixpkgs has V1.
  opencodeV2Bundle = pkgs.fetchzip {
    url = "https://registry.npmjs.org/@opencode/cli-darwin-arm64/-/cli-darwin-arm64-${opencodeV2Version}.tgz";
    hash = "sha256-NiD8JtQjJkI1D/U40M2TbfjCw6aifz3JBov/xu7UsXU=";
  };

  # Like the nixpkgs V1 wrapper: ripgrep from nixpkgs instead of a downloaded
  # copy, and no self-update. The background service inherits this environment.
  opencodeV2 = pkgs.writeShellApplication {
    name = "opencode";
    runtimeInputs = [ pkgs.ripgrep ];
    runtimeEnv = {
      OPENCODE_DISABLE_AUTOUPDATE = "1";
      # Preserve the existing V2 session/auth database across the profile cleanup.
      OPENCODE_DB = "opencode-v2.db";
    };
    text = ''exec ${opencodeV2Bundle}/bin/opencode "$@"'';
  };

  opencodeConfigDirectory = "${config.xdg.configHome}/opencode";
  lspTools = pkgs.writeShellApplication {
    name = "lsp-tools-mcp";
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
    package = opencodeV2;
    settings = {
      plugins = [ anthropicAuthPluginV2 ];
      mcp = {
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
        grep_app = {
          type = "remote";
          url = "https://mcp.grep.app";
        };
        lsp = {
          type = "local";
          command = [ (lib.getExe lspTools) ];
        };
        figma = {
          type = "remote";
          url = "http://127.0.0.1:3845/mcp";
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
      git-master = ./vendor/skills/git-master;
      lsp-setup = ./vendor/skills/lsp-setup;
      playwright = ./skills/playwright;
      visual-qa = ./vendor/skills/visual-qa;
    };
  };

  home.packages = [
    codegraph
    lspTools
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
