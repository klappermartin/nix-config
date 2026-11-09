{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  ds4 = pkgs.stdenv.mkDerivation {
    pname = "ds4";
    version = inputs.ds4.shortRev or inputs.ds4.rev or "unstable";
    src = inputs.ds4;

    # DS4 uses Metal 4 APIs, which require the macOS 26 SDK rather than the
    # default SDK selected by nixpkgs' Darwin stdenv.
    nativeBuildInputs = [ pkgs.makeWrapper ];
    buildInputs = [
      pkgs.apple-sdk_26
      (pkgs.darwinMinVersionHook "15.0")
    ];

    buildPhase = ''
      runHook preBuild
      make
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin" "$out/libexec" "$out/share/ds4"
      install -m755 ds4 ds4-agent ds4-bench ds4-eval ds4-server "$out/libexec/"
      cp -R metal "$out/share/ds4/"
      install -m755 download_model.sh "$out/share/ds4/"

      for program in ds4 ds4-agent ds4-bench ds4-eval ds4-server; do
        makeWrapper "$out/libexec/$program" "$out/bin/$program" \
          --run "cd $out/share/ds4"
      done

      runHook postInstall
    '';

    meta = {
      description = "DwarfStar local inference engine";
      homepage = "https://github.com/antirez/ds4";
      license = lib.licenses.mit;
      platforms = lib.platforms.darwin;
    };
  };

  ds4DataDirectory = "${config.xdg.dataHome}/ds4";
  ds4CacheDirectory = "${config.xdg.cacheHome}/ds4";
  ds4Download = pkgs.writeShellApplication {
    name = "ds4-download";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
    ];
    text = ''
      data_dir=${lib.escapeShellArg ds4DataDirectory}
      mkdir -p "$data_dir"
      install -m755 ${lib.escapeShellArg "${ds4}/share/ds4/download_model.sh"} "$data_dir/download_model.sh"
      exec "$data_dir/download_model.sh" "$@"
    '';
  };
  ds4Service = pkgs.writeShellApplication {
    name = "ds4-service";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      model=${lib.escapeShellArg "${ds4DataDirectory}/ds4flash.gguf"}
      if [[ ! -e "$model" ]]; then
        echo "ds4: no model installed; run: ds4-download ds4f-q2" >&2
        exit 1
      fi

      mkdir -p ${lib.escapeShellArg ds4CacheDirectory}

      exec ${lib.escapeShellArg "${ds4}/bin/ds4-server"} \
        -m "$model" \
        --ssd-streaming \
        --ctx 32768 \
        --kv-disk-dir ${lib.escapeShellArg ds4CacheDirectory} \
        --kv-disk-space-mb 8192
    '';
  };
  ds4Start = pkgs.writeShellApplication {
    name = "ds4-start";
    text = ''
      exec /bin/launchctl kickstart -k "gui/$UID/org.nix-community.home.ds4"
    '';
  };
  ds4Stop = pkgs.writeShellApplication {
    name = "ds4-stop";
    text = ''
      exec /bin/launchctl kill SIGTERM "gui/$UID/org.nix-community.home.ds4"
    '';
  };
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
        context = 40960;
        output = 8192;
      };
    };
    "qwen3:14b" = {
      name = "Qwen3 14B (default local)";
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
      name = "Qwen3 30B-A3B (quality local)";
      capabilities = {
        tools = true;
        input = [ "text" ];
        output = [ "text" ];
      };
      limit = {
        context = 65536;
        output = 16384;
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
        context = 65536;
        output = 16384;
      };
    };
  };
in
{
  imports = [ ../../../darwin/home/services/ollama.nix ];

  home.packages = [
    ds4
    ds4Download
    ds4Start
    ds4Stop
    pkgs.ollama
  ];

  # Register DS4 without starting it. The weights are intentionally mutable
  # and its model occupies much of this machine's unified memory while loaded;
  # use ds4-start and ds4-stop to control that explicitly.
  launchd.agents.ds4 = {
    enable = true;
    config = {
      ProgramArguments = [ "${ds4Service}/bin/ds4-service" ];
      RunAtLoad = false;
      KeepAlive = false;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/ds4.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/ds4.err.log";
    };
  };

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
