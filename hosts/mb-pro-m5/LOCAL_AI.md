# M5 local AI models

Ollama is installed and served by the M5 configuration, but **models are never
downloaded during activation**. The declarations in
[`modules/darwin/home/local-ai.nix`](../../modules/darwin/home/local-ai.nix)
only make this intended model set visible to OpenCode.

Pull a model explicitly on the M5, after `darwin-rebuild switch` has started
the Ollama service:

```sh
ollama pull <model>
```

| Model | Use now | Role | Approx. download | Expected M5 Max speed | Add explicitly |
| --- | --- | --- | ---: | ---: | --- |
| `qwen3:8b` | Optional | Fast chat, short edits, quick tool work | 5.2 GB | 90–110 tok/s | `ollama pull qwen3:8b` |
| `qwen3:14b` | Yes | Default local general/reasoning model | 9.3 GB | 50–65 tok/s | `ollama pull qwen3:14b` |
| `qwen3:30b` | Optional | Higher-quality general model | 19 GB | MoE; workload-dependent | `ollama pull qwen3:30b` |
| `qwen3-coder:30b` | Yes | Repository-scale coding and agent tasks | 19 GB | MoE; workload-dependent | `ollama pull qwen3-coder:30b` |

Start with `qwen3:14b` and `qwen3-coder:30b`; pull `qwen3:8b` only if the
extra responsiveness is useful, and `qwen3:30b` when a general-purpose quality
tier is wanted. Check installed models with `ollama ls`, remove one with
`ollama rm <model>`, and use only one heavyweight model at a time because they
share the Mac's 64GB unified memory with macOS and ds4.
