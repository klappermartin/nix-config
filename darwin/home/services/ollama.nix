{
  config,
  pkgs,
  ...
}:
{
  # `ollama` itself lives in darwin/home/packages.nix.

  # Ollama has no Home Manager service module on Darwin. Run it as a user
  # launchd agent so OpenCode's local discovery always finds it.
  launchd.agents.ollama = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.ollama}/bin/ollama"
        "serve"
      ];
      EnvironmentVariables = {
        OLLAMA_HOST = "127.0.0.1:11434";
        # Agent prompts need more than Ollama's small default context.
        OLLAMA_CONTEXT_LENGTH = "65536";
        # Keep the model loaded between OpenCode turns, but not indefinitely:
        # ds4 needs the same unified memory for its expert cache.
        OLLAMA_KEEP_ALIVE = "15m";
        OLLAMA_FLASH_ATTENTION = "1";
      };
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/ollama.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/ollama.err.log";
    };
  };
}
