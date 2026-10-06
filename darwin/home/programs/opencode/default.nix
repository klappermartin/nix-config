{
  config,
  lib,
  pkgs,
  ...
}:
let
  jsonFormat = pkgs.formats.json { };

  # Stay on 1.x (2.x needs OpenCode v2). Anthropic gates models on the Claude
  # Code version this plugin reports; on 400 `claude_code_version_too_old`, bump
  # it or set `ANTHROPIC_CLAUDE_CODE_VERSION`.
  anthropicAuthPlugin = "@ex-machina/opencode-anthropic-auth@1.8.6";
  omoPluginVersion = "4.19.4";
  omoPlugin = "oh-my-openagent@${omoPluginVersion}";
  codegraphVersion = "1.6.2";

  omoSrc = pkgs.fetchzip {
    url = "https://registry.npmjs.org/oh-my-openagent/-/oh-my-openagent-${omoPluginVersion}.tgz";
    hash = "sha256-UVs08W8azRuGgj58WCuctrn2ASnQyFG473/ecIeHIxY=";
  };

  # The main npm package is only a launcher; the runnable bundle ships per platform.
  codegraphBundle = pkgs.fetchzip {
    url = "https://registry.npmjs.org/@colbymchenry/codegraph-darwin-arm64/-/codegraph-darwin-arm64-${codegraphVersion}.tgz";
    hash = "sha256-d88aph8IJbcjcQGuJRV0PlIGyQ/hkaOJ6k8RRkILrq8=";
  };

  codegraph = pkgs.writeShellApplication {
    name = "codegraph";
    runtimeEnv = {
      CODEGRAPH_TELEMETRY = "0";
      DO_NOT_TRACK = "1";
    };
    text = ''exec ${codegraphBundle}/bin/codegraph "$@"'';
  };

  switcher = pkgs.writeShellApplication {
    name = "activate-oh-my-openagent-profile.sh";
    runtimeInputs = [ pkgs.coreutils ];
    text = builtins.readFile ./activate-oh-my-openagent-profile.sh;
  };

  omoDirectory = "${config.home.homeDirectory}/.omo";
  opencodeConfigDirectory = "${config.xdg.configHome}/opencode";
  omoServerConfigPath = "${opencodeConfigDirectory}/omo.json";
  omoTuiConfigPath = "${opencodeConfigDirectory}/omo-tui.json";

  # Extra configs can only add plugins, not remove them, so `opencode.json`
  # stays lite and `opencode-omo` adds omo via these files. See README.md.
  omoServerConfig = jsonFormat.generate "opencode-omo.json" {
    "$schema" = "https://opencode.ai/config.json";
    plugin = [ omoPlugin ];
  };

  omoTuiConfig = jsonFormat.generate "opencode-omo-tui.json" {
    "$schema" = "https://opencode.ai/tui.json";
    plugin = [ omoPlugin ];
  };

  opencodeOmo = pkgs.writeShellApplication {
    name = "opencode-omo";
    text = ''
      export OPENCODE_CONFIG=${lib.escapeShellArg omoServerConfigPath}
      export OPENCODE_TUI_CONFIG=${lib.escapeShellArg omoTuiConfigPath}
      # omo's codegraph auto-init uses this binary instead of provisioning its own.
      export OMO_CODEGRAPH_BIN=${lib.escapeShellArg (lib.getExe codegraph)}
      exec ${lib.escapeShellArg "${config.programs.opencode.package}/bin/opencode"} "$@"
    '';
  };
in
{
  programs.opencode = {
    enable = true;
    settings = {
      # No omo here; `opencode-omo` adds it.
      plugin = [ anthropicAuthPlugin ];
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
          command = [
            "${pkgs.nodejs_22}/bin/node"
            "${omoSrc}/packages/lsp-tools-mcp/dist/cli.js"
          ];
          environment = {
            LSP_TOOLS_MCP_USER_CONFIG = "${opencodeConfigDirectory}/lsp.json";
            LSP_TOOLS_MCP_INSTALL_DECISIONS = "${opencodeConfigDirectory}/lsp-install-decisions.json";
            LSP_TOOLS_MCP_PROJECT_CONFIG = ".opencode/lsp.json:.omo/lsp.json:.omo/lsp-client.json";
          };
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
      ast-grep = "${omoSrc}/packages/shared-skills/skills/ast-grep";
      git-master = "${omoSrc}/packages/shared-skills/skills/git-master";
      lsp-setup = "${omoSrc}/packages/shared-skills/skills/lsp-setup";
      playwright = ./skills/playwright;
      visual-qa = "${omoSrc}/packages/shared-skills/skills/visual-qa";
    };
    # Keeps tui.json managed, overwriting omo's earlier self-heal edits.
    tui.plugin = [ ];
  };

  home.packages = [
    switcher
    opencodeOmo
    codegraph
  ];
  home.file = {
    ".omo/omo.anthropic.jsonc".source = ./omo.anthropic.jsonc;
    ".omo/omo.openai.jsonc".source = ./omo.openai.jsonc;
    ".omo/omo.opencode-go.jsonc".source = ./omo.opencode-go.jsonc;
  };
  xdg.configFile = {
    "opencode/activate-oh-my-openagent-profile.sh".source =
      "${switcher}/bin/activate-oh-my-openagent-profile.sh";
    "opencode/omo.json".source = omoServerConfig;
    "opencode/omo-tui.json".source = omoTuiConfig;
  };

  # The switcher owns the active file; rebuilds must preserve the selected profile.
  home.activation.initializeOmoProfile = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [[ ! -e ${lib.escapeShellArg "${omoDirectory}/omo.jsonc"} && ! -L ${lib.escapeShellArg "${omoDirectory}/omo.jsonc"} ]]; then
      run ${pkgs.coreutils}/bin/ln -s omo.anthropic.jsonc ${lib.escapeShellArg "${omoDirectory}/omo.jsonc"}
    fi
  '';
}
