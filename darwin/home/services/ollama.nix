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
        # Reserve 64K tokens for coding-agent prompt/tool history and up to
        # 16K tokens for output. The smaller Qwen models retain their native
        # 40K limit and are intended only for short tasks.
        OLLAMA_CONTEXT_LENGTH = "81920";
        # Halves KV-cache memory with no usually noticeable quality loss.
        # Requires flash attention, which is explicitly enabled below.
        OLLAMA_KV_CACHE_TYPE = "q8_0";
        # Keep the model loaded between OpenCode turns, but not indefinitely.
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
