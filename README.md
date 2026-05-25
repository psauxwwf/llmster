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
