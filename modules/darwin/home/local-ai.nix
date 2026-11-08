{ pkgs, ... }:
{
  imports = [ ../../../darwin/home/services/ollama.nix ];

  home.packages = [ pkgs.ollama ];

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
