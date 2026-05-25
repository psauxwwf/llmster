# llmster

`llmster` packages LM Studio headless server into Docker images for four runtime variants:

- CPU
- NVIDIA
- AMD
- Intel

The repository exists to make LM Studio easier to run as a local containerized service with a small Docker Compose setup, persistent model storage, and hardware-specific overrides.

## What This Project Does

- Runs LM Studio in headless mode inside Docker
- Exposes the LM Studio API on `127.0.0.1:1234`
- Persists downloaded models in `./data/models`
- Persists LM Studio extensions in `./data/extensions`
- Provides separate Compose overrides for CPU, NVIDIA, AMD, and Intel environments
- Includes Taskfile commands for maintainers who build and publish the images

### Optional Host Paths

By default, Compose mounts local project directories:

- `./data/models`
- `./data/extensions`
- `./data/internal`

You can override them with environment variables:

- `LMS_MODELS_DIR`
- `LMS_EXTENSIONS_DIR`
- `LMS_INTERNAL_DIR`

This is useful when the desktop LM Studio already works on your machine and you want the container to reuse the same downloaded models, backends/extensions, and saved internal configuration instead of creating a separate runtime state.

Example:

```bash
LMS_MODELS_DIR="$HOME/.lmstudio/models" \
LMS_EXTENSIONS_DIR="$HOME/.lmstudio/extensions" \
LMS_INTERNAL_DIR="$HOME/.lmstudio/.internal" \
docker compose --project-directory . -f docker/docker-compose.yaml -f docker/docker-compose.nvidia.yaml up -d llmster
```

If you configured a model in the desktop app and clicked save, the load settings are usually stored under:

- `~/.lmstudio/.internal/user-concrete-model-default-config/`

The preferred backend selection is usually stored in:

- `~/.lmstudio/.internal/backend-preferences-v1.json`
- `~/.lmstudio/.internal/hardware-config.json`

Mounting `LMS_INTERNAL_DIR` lets the container reuse those saved settings.

## For Users

Users do not need to build images locally. Pull the published image for your hardware variant and start it with Docker Compose.

### CPU

```bash
docker compose --project-directory . -f docker/docker-compose.yaml pull llmster
docker compose --project-directory . -f docker/docker-compose.yaml up -d llmster
```

### NVIDIA

```bash
docker compose --project-directory . -f docker/docker-compose.yaml -f docker/docker-compose.nvidia.yaml pull llmster
docker compose --project-directory . -f docker/docker-compose.yaml -f docker/docker-compose.nvidia.yaml up -d llmster
```

### AMD

```bash
docker compose --project-directory . -f docker/docker-compose.yaml -f docker/docker-compose.amd.yaml pull llmster
docker compose --project-directory . -f docker/docker-compose.yaml -f docker/docker-compose.amd.yaml up -d llmster
```

### Intel

```bash
docker compose --project-directory . -f docker/docker-compose.yaml -f docker/docker-compose.intel.yaml pull llmster
docker compose --project-directory . -f docker/docker-compose.yaml -f docker/docker-compose.intel.yaml up -d llmster
```

### Stop the Service

```bash
docker compose --project-directory . -f docker/docker-compose.yaml down
```

### Check Logs

```bash
docker compose --project-directory . -f docker/docker-compose.yaml logs -f llmster
```

### Test the API

```bash
curl http://127.0.0.1:1234/v1/models
```

### Load a Model with Lower VRAM Usage

The headless server does not expose load-tuning flags on `lms server start`, but LM Studio does support them when you load the model explicitly.

Example:

```bash
docker exec -it llmster lms load qwen3.5-2b \
  --gpu 0.5 \
  --context-length 4096 \
  --parallel 1 \
  --identifier qwen3.5-2b \
  -y
```

If you want to automate the same thing over HTTP, the native `POST /api/v1/models/load` endpoint also supports load-time tuning such as `context_length`, `eval_batch_size`, `offload_kv_cache_to_gpu`, and `flash_attention`.

### Reuse Saved Desktop Load Settings in the Container

If you already downloaded a model in the desktop LM Studio app, tuned its load settings, and saved them, the container can reuse the same configuration.

Use the same host LM Studio directories for:

- models: `LMS_MODELS_DIR`
- extensions/backends: `LMS_EXTENSIONS_DIR`
- internal saved settings: `LMS_INTERNAL_DIR`

Example:

```bash
LMS_MODELS_DIR="$HOME/.lmstudio/models" \
LMS_EXTENSIONS_DIR="$HOME/.lmstudio/extensions" \
LMS_INTERNAL_DIR="$HOME/.lmstudio/.internal" \
docker compose --project-directory . -f docker/docker-compose.yaml -f docker/docker-compose.nvidia.yaml up -d llmster
```

With that setup, the container sees the same downloaded model files, the same installed runtime backends, and the same saved per-model load config that the desktop app uses.

If you prefer not to share the whole LM Studio state, copy only the saved load config files into the container's `.internal` directory, especially:

- `user-concrete-model-default-config/`
- `backend-preferences-v1.json`
- `hardware-config.json`

Example model-specific saved load config path:

- `~/.lmstudio/.internal/user-concrete-model-default-config/HauhauCS/Qwen3.5-2B-Uncensored-HauhauCS-Aggressive/Qwen3.5-2B-Uncensored-HauhauCS-Aggressive-Q4_K_M.gguf.json`

For one-off manual tuning inside the container, you can also bypass the saved config entirely and load the model explicitly:

```bash
docker exec -it llmster lms load qwen3.5-2b \
  --gpu 0.5 \
  --context-length 4096 \
  --parallel 1 \
  --identifier qwen3.5-2b \
  -y
```

### Download a Model

To download a model into the running container:

```bash
docker exec -it llmster lms get https://huggingface.co/lmstudio-community/Qwen3.5-2B-GGUF
```

### Update All Runtimes

To update all LM Studio runtimes inside the running container:

```bash
docker exec -it llmster lms runtime update --all
```

### Runtime Cheat Sheet

List installed runtimes:

```bash
lms runtime ls
```

Search available runtimes:

```bash
lms runtime get --list "llama.cpp"
```

Search by acceleration type:

```bash
lms runtime get --list "llama.cpp:cuda"
lms runtime get --list "llama.cpp:vulkan"
```

Include incompatible runtimes in search results:

```bash
lms runtime get --list --allow-incompatible "llama.cpp:cuda"
```

Install a runtime:

```bash
lms runtime get "llama.cpp-linux-x86_64-nvidia-cuda-avx2" -y
```

Install a specific version:

```bash
lms runtime get "llama.cpp-linux-x86_64-nvidia-cuda-avx2@2.16.0" -y
```

Select an installed runtime:

```bash
lms runtime select "llama.cpp-linux-x86_64-nvidia-cuda-avx2"
```

Select the latest installed version:

```bash
lms runtime select "llama.cpp-linux-x86_64-nvidia-cuda-avx2" --latest
```

Remove a runtime:

```bash
lms runtime remove "llama.cpp-linux-x86_64-nvidia-cuda12-avx2" -y
```

Common runtime name patterns:

- `llama.cpp-linux-x86_64-avx2`: CPU
- `llama.cpp-linux-x86_64-nvidia-cuda-avx2`: NVIDIA CUDA
- `llama.cpp-linux-x86_64-nvidia-cuda12-avx2`: NVIDIA CUDA 12
- `llama.cpp-linux-x86_64-vulkan-avx2`: Vulkan

Recommended workflow:

1. Run `lms runtime ls`
2. Run `lms runtime get --list "llama.cpp:cuda"`
3. If nothing useful appears, repeat with `--allow-incompatible`
4. Install with `lms runtime get ...`
5. Activate with `lms runtime select ...`
6. Remove conflicting runtimes with `lms runtime remove ...` if needed

Container equivalents:

```bash
docker exec -it llmster lms runtime ls
docker exec -it llmster lms runtime get --list --allow-incompatible "llama.cpp:cuda"
docker exec -it llmster lms runtime get "llama.cpp-linux-x86_64-nvidia-cuda-avx2" -y
docker exec -it llmster lms runtime select "llama.cpp-linux-x86_64-nvidia-cuda-avx2" --latest
```

## Images

- `ghcr.io/psauxwwf/llmster:cpu`
- `ghcr.io/psauxwwf/llmster:nvidia`
- `ghcr.io/psauxwwf/llmster:amd`
- `ghcr.io/psauxwwf/llmster:intel`

## For Maintainers

The `Taskfile.yml` is intended for image builders and publishers and uses the same base Compose file plus hardware-specific overrides.

Examples:

```bash
task build
task pull
task push
task up:cpu
task up:nvidia
```

## Main Links

- LM Studio: https://lmstudio.ai/
- LM Studio developer docs: https://lmstudio.ai/docs/developer
- LM Studio headless mode: https://lmstudio.ai/docs/developer/core/headless
- LM Studio CLI docs: https://lmstudio.ai/docs/cli
- LM Studio OpenAI-compatible API: https://lmstudio.ai/docs/developer/openai-compat
