{
  pkgs,
  ...
}:
let
  # These declarations make the intended M5 models selectable in OpenCode.
  # They do not download models; see hosts/mb-pro-m5/LOCAL_AI.md for the
  # explicit, on-demand pull commands.
  ollamaModels = {
    "qwen3:8b" = {
      name = "Qwen3 8B (short-task local)";
      capabilities = {
        tools = true;
        input = [ "text" ];
        output = [ "text" ];
      };
      limit = {
        context = 40960;
        output = 8192;
      };
    };
    "qwen3:14b" = {
      name = "Qwen3 14B (short-task local)";
      # Qwen3 can emit its entire tool-use decision as reasoning, leaving no
      # tool call for OpenCode to execute. Disable reasoning for agent turns.
      body.reasoning_effort = "none";
      capabilities = {
        tools = true;
        input = [ "text" ];
        output = [ "text" ];
      };
      limit = {
        context = 40960;
        output = 8192;
      };
    };
    "qwen3:30b" = {
      name = "Qwen3 30B-A3B (short-task local)";
      capabilities = {
        tools = true;
        input = [ "text" ];
        output = [ "text" ];
      };
      limit = {
        context = 40960;
        output = 8192;
      };
    };
    "qwen3-coder:30b" = {
      name = "Qwen3-Coder 30B (local coding agent)";
      capabilities = {
        tools = true;
        input = [ "text" ];
        output = [ "text" ];
      };
      limit = {
        # Reserve 64K tokens for the agent's prompt and tool history, plus up
        # to 16K tokens for its response. This is the only documented model
        # here with a native context window large enough for coding agents.
        context = 81920;
        output = 16384;
      };
    };
  };
in
{
  imports = [ ../../../darwin/home/services/ollama.nix ];

  home.packages = [ pkgs.ollama ];

  # The Ollama provider discovers pulled models automatically. Keeping this
  # explicit catalogue additionally documents and exposes our intended set,
  # even before a model has been pulled.
  programs.opencode.settings.providers.ollama.models = ollamaModels;
}
