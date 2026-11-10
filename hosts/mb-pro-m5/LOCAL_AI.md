# M5 local AI models

Ollama is installed and served by the M5 configuration, but **models are never
downloaded during activation**. The declarations in
[`modules/darwin/home/local-ai.nix`](../../modules/darwin/home/local-ai.nix)
make this intended model set visible to OpenCode.

Pull a model explicitly on the M5, after `darwin-rebuild switch` has started
the Ollama service:

```sh
ollama pull <model>
```

| Model | Use now | Role | Approx. download | Expected M5 Max speed | Add explicitly |
| --- | --- | --- | ---: | ---: | --- |
| `qwen3:8b` | Optional | Fast chat, short edits, quick tool work | 5.2 GB | 90–110 tok/s | `ollama pull qwen3:8b` |
| `qwen3:14b` | Optional | Higher-quality chat and short tool work | 9.3 GB | 50–65 tok/s | `ollama pull qwen3:14b` |
| `qwen3:30b` | Optional | Higher-quality general short tasks | 19 GB | MoE; workload-dependent | `ollama pull qwen3:30b` |
| `qwen3-coder:30b` | Yes | Primary repository-scale coding and agent model | 19 GB | MoE; workload-dependent | `ollama pull qwen3-coder:30b` |

Use `qwen3-coder:30b` for OpenCode and other agentic coding. It has a 262K
native context window; Ollama is configured with an 80K runtime context so the
agent can retain about 64K tokens of prompt and tool history plus up to 16K of
output. The regular Qwen3 models have a 40K native context window, below the
64K context Ollama recommends for coding agents, so reserve them for short
tasks.

Pull the coder model first. Pull the smaller or general-purpose models only
when their shorter-task roles are useful. Check installed models with `ollama
ls`, remove one with `ollama rm <model>`, and use one heavyweight model at a
time so it has room alongside macOS in the Mac's 64 GB unified memory.
