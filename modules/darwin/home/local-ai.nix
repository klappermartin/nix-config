{ pkgs, ... }:
let
  # These declarations make the intended M5 models selectable in OpenCode.
  # They do not download models; see hosts/mb-pro-m5/LOCAL_AI.md for the
  # explicit, on-demand pull commands.
  ollamaModels = {
    "qwen3:8b" = {
      name = "Qwen3 8B (fast local)";
      capabilities = {
        tools = true;
        input = [ "text" ];
        output = [ "text" ];
      };
      limit = {
        context = 32768;
        output = 8192;
      };
    };
    "qwen3:14b" = {
      name = "Qwen3 14B (default local)";
      capabilities = {
        tools = true;
        input = [ "text" ];
        output = [ "text" ];
      };
      limit = {
        context = 32768;
        output = 8192;
      };
    };
    "qwen3:30b" = {
      name = "Qwen3 30B-A3B (quality local)";
      capabilities = {
        tools = true;
        input = [ "text" ];
        output = [ "text" ];
      };
      limit = {
        context = 32768;
        output = 8192;
      };
    };
    "qwen3-coder:30b" = {
      name = "Qwen3-Coder 30B (code local)";
      capabilities = {
        tools = true;
        input = [ "text" ];
        output = [ "text" ];
      };
      limit = {
        context = 32768;
        output = 8192;
      };
    };
  };
in
{
  imports = [ ../../../darwin/home/services/ollama.nix ];

  home.packages = [ pkgs.ollama ];

  # The Ollama provider discovers pulled models automatically.  Keeping this
  # explicit catalogue additionally documents and exposes our intended set,
  # even before a model has been pulled.
  programs.opencode.settings.providers.ollama.models = ollamaModels;

  # Ollama is discovered automatically at 127.0.0.1:11434. ds4 exposes an
  # OpenAI-compatible endpoint and is specific to the M5's local-AI setup.
  programs.opencode.settings.providers.ds4 = {
    name = "DwarfStar (local)";
    package = "@opencode/ai/providers/openai-compatible";
    settings = {
      baseURL = "http://127.0.0.1:8000/v1";
      apiKey = "dsv4-local";
      # Streamed 284B prefill can take minutes before the first chunk.
      headerTimeout = 1800000;
      chunkTimeout = false;
    };
    models."deepseek-v4-flash" = {
      name = "DwarfStar Flash";
      compatibility = {
        maxTokensField = "max_tokens";
        reasoningField = "reasoning_content";
      };
      capabilities = {
        tools = true;
        input = [ "text" ];
        output = [ "text" ];
      };
      limit = {
        context = 32768;
        output = 8192;
      };
    };
  };
}
