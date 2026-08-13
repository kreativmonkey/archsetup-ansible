# ollama

Installs ollama with a GPU acceleration backend, configures the service through
a systemd drop-in, pulls the configured models and builds the customised
variants.

## What it does

| Area | How |
|------|-----|
| **Packages** | `ollama`, `ollama_acceleration_package` (default `ollama-rocm`) and `rocm-smi-lib`. |
| **GPU access** | The `ollama` service account joins `render` and `video` through the `system_user` role. |
| **Service config** | `/etc/systemd/system/ollama.service.d/override.conf` from `ollama_environment_variables`. |
| **Models** | Pulled only when `ollama list` does not show them. |
| **Customisations** | A Modelfile per entry under `/etc/ollama/modelfiles`, then `ollama create` for the ones that changed. |

## Example Playbook

```yaml
- name: Install ollama
  ansible.builtin.import_role:
    name: ollama
  vars:
    ollama_acceleration_package: ollama-rocm
    ollama_models:
      - qwen3-coder:30b
```

## Notes

- **`render` and `video` are what make the GPU work.** Without them ollama
  cannot open `/dev/dri` or `/dev/kfd` and silently falls back to CPU inference
  — which looks like "the model is just slow", not like a broken setup.
- **`ollama pull` and `ollama create` always report success**, so neither is
  idempotent on its own. The role reads `ollama list` first and only pulls what
  is missing.
- **The Modelfiles live on disk under `/etc/ollama/modelfiles`.** They used to be
  written to a fixed path in `/tmp` by a shell one-liner and deleted again, so
  `ollama create` ran on every play and two parallel runs would have raced over
  the same file. On disk the file *is* the comparable state: `ollama create` only
  runs for an entry whose Modelfile actually changed.
- **`flush_handlers` before touching the models.** Pulls and customisations talk
  to the running service, so a pending restart from the drop-in has to happen
  first.
- **`HSA_OVERRIDE_GFX_VERSION`** in the defaults is what makes ROCm accept the
  Radeon 890M (gfx1150). Wrong value, no GPU.
