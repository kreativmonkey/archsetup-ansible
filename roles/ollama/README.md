# Ollama Role

This role installs and configures [Ollama](https://ollama.com/) on Arch Linux, optimized for GPU acceleration and local model performance.

## Features

- Installs `ollama` and selected acceleration package (`cuda`, `rocm`, `vulkan`).
- Configures systemd overrides for environment variables.
- Optimizes for Gemma 4 models.
- Automatically pulls specified models.
- Ensures GPU access for the `ollama` user.

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ollama_acceleration_package` | `ollama-rocm` | The package for GPU acceleration. |
| `ollama_models` | `[gemma4:e4b]` | List of models to pull. |
| `ollama_environment_variables` | (see defaults) | Environment variables for performance tuning. |

## Optimizations for Gemma 4

- `OLLAMA_FLASH_ATTENTION=1`: Faster inference.
- `OLLAMA_KV_CACHE_TYPE=q8_0`: Reduced VRAM usage.
- `OLLAMA_MAX_LOADED_MODELS=1`: Ensures the model fits in VRAM without swapping.
