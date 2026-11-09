# M5 local AI models

Ollama and DS4 are installed and served by the M5 configuration, but **models
are never downloaded during activation**. The declarations in
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

## DS4 / DwarfStar

DS4 is packaged from the flake's locked [`ds4`](../../flake.nix) input. The
upstream project has no release tags yet, so it is pinned to a reviewed commit;
update it deliberately with:

```sh
nix flake update ds4
```

DS4 is registered but does not start automatically. Download its default model
explicitly into the mutable data directory:

```sh
ds4-download ds4f-q2
```

This is an approximately 81 GiB download. On this 64 GB M5, DS4 uses SSD
streaming and exposes its OpenAI-compatible endpoint at
`http://127.0.0.1:8000/v1`. The downloaded weights consume disk space only;
load them into memory when wanted:

```sh
ds4-start
```

Release DS4's unified-memory allocation without deleting the weights:

```sh
ds4-stop
```

Confirm it has started with:

```sh
curl http://127.0.0.1:8000/v1/models
```

Select `ds4/deepseek-v4-flash` (DwarfStar Flash) in OpenCode. The model lives
under `~/.local/share/ds4`, outside the Nix store; remove that directory only
when you intentionally want to reclaim the model's disk space.
