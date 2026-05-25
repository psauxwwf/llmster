# llmster

`llmster` packages LM Studio headless server into Docker images for four runtime profiles:

- CPU
- NVIDIA
- AMD
- Intel

The repository exists to make LM Studio easier to run as a local containerized service with a small Docker Compose setup, persistent model storage, and hardware-specific profiles.

## What This Project Does

- Runs LM Studio in headless mode inside Docker
- Exposes the LM Studio API on `127.0.0.1:1234`
- Persists downloaded models in `./data/lmstudio-models`
- Provides separate Compose profiles for CPU, NVIDIA, AMD, and Intel environments
- Includes Taskfile commands for maintainers who build and publish the images

## For Users

Users do not need to build images locally. Pull the published image for your hardware profile and start it with Docker Compose.

### CPU

```bash
docker compose --profile cpu pull llmster
docker compose --profile cpu up -d llmster
```

### NVIDIA

```bash
docker compose --profile nvidia pull nvidia
docker compose --profile nvidia up -d nvidia
```

### AMD

```bash
docker compose --profile amd pull amd
docker compose --profile amd up -d amd
```

### Intel

```bash
docker compose --profile intel pull intel
docker compose --profile intel up -d intel
```

### Stop the Service

```bash
docker compose down
```

### Check Logs

```bash
docker compose logs -f
```

### Test the API

```bash
curl http://127.0.0.1:1234/v1/models
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

## Images

- `ghcr.io/psauxwwf/llmster:cpu`
- `ghcr.io/psauxwwf/llmster:nvidia`
- `ghcr.io/psauxwwf/llmster:amd`
- `ghcr.io/psauxwwf/llmster:intel`

## For Maintainers

The `Taskfile.yml` is intended for image builders and publishers.

Examples:

```bash
task build
task push
task up:cpu
```

## Main Links

- LM Studio: https://lmstudio.ai/
- LM Studio developer docs: https://lmstudio.ai/docs/developer
- LM Studio headless mode: https://lmstudio.ai/docs/developer/core/headless
- LM Studio CLI docs: https://lmstudio.ai/docs/cli
- LM Studio OpenAI-compatible API: https://lmstudio.ai/docs/developer/openai-compat
