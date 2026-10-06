# llama_server

Runs a local LLM with llama.cpp's `llama-server` on the GPU through Vulkan, as a
systemd user service with an OpenAI-compatible API and a web UI on
`http://localhost:8080`. Default model is Qwen3.6-35B-A3B.

Replaces the former `ollama` role and removes what that one left behind.

## Example Playbook

```yaml
- name: Run the local LLM
  ansible.builtin.import_role:
    name: llama_server
  vars:
    llama_server_model:
      repo: unsloth/Qwen3.6-35B-A3B-GGUF
      file: Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf
      mmproj: mmproj-F16.gguf
      alias: qwen3.6
```

## Notes

- **Why not ollama.** On the Radeon 890M (Strix Point) ollama 0.35 dropped the
  iGPU ("dropping integrated GPU") and ran everything on the CPU, behind a ROCm
  setup that only worked with `HSA_OVERRIDE_GFX_VERSION`. llama.cpp on Vulkan
  measured 563 t/s prompt processing and 22 t/s generation for Qwen3.6-35B-A3B,
  against 110 and 18 t/s on the CPU.
- **Vulkan, not ROCm.** On RDNA3.5 iGPUs Vulkan is at least as fast for
  generation and needs no gfx overrides. The only system package is the Mesa
  driver.
- **The release is pinned.** llama.cpp renames flags between builds
  (`--no-mmap` became `--load-mode none`), and an unknown flag is a hard start
  failure. Bump `llama_server_release` and check `llama-server --help` against
  `llama_server_args` in one go.
- **iGPU memory is the GTT limit**, half the RAM by default (~31 GB with
  64 GB). Model plus KV cache have to fit into that.
- **The downloads are big.** The model is 21 GB; `get_url` fetches it only when
  the file is missing, so check free disk space before changing the model.
- **The ollama removal is one-way** (`llama_server_remove_ollama`): service,
  packages with their ROCm dependencies, `/var/lib/ollama` and `~/.ollama`.
