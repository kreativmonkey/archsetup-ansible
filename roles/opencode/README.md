# opencode

Installs the language servers opencode drives and renders
`~/.config/opencode/opencode.json` — providers, agents, LSP and MCP servers,
pointed at the local ollama endpoint.

**This role owns `opencode.json`.** Other roles add to it through the entry
points below.

## Entry points

The configuration itself:

```yaml
- name: Configure opencode
  ansible.builtin.import_role:
    name: opencode
```

Register a provider — what `headroom` uses:

```yaml
- name: Register headroom as an opencode provider
  ansible.builtin.include_role:
    name: opencode
    tasks_from: add_provider
  vars:
    opencode_provider:
      name: headroom
      config:
        npm: "@ai-sdk/openai-compatible"
        name: Headroom (via local proxy)
        options:
          baseURL: "http://localhost:8787/v1"
```

Register an MCP server:

```yaml
- name: Register the headroom MCP server
  ansible.builtin.include_role:
    name: opencode
    tasks_from: add_mcp_server
  vars:
    opencode_mcp_server:
      name: headroom
      config:
        type: local
        command: ["/home/sebastian/.local/bin/headroom", "mcp", "start"]
        enabled: true
```

## Notes

- **`headroom` used to rewrite this file with `ansible.builtin.replace`**,
  matching `"provider": {` and pasting a JSON block in front of it. That
  mutated a file this role renders from a template, so the next opencode run
  overwrote it — and the regexp silently did nothing whenever the formatting
  changed. Both additions go through `add_provider` / `add_mcp_server` now.
- **The additions accumulate.** Each entry point merges into
  `opencode_providers_extra` / `opencode_mcp_extra` with `set_fact` and then
  re-renders, so two roles can register something without the second dropping
  the first.
- **`opencode_permissions` is `allow` throughout** because the models are local
  — nothing leaves the host.
- **The template no longer names the agents.** It used to list
  `plan`/`build`/`doc` explicitly, so a fourth agent in `opencode_agents` was
  silently dropped.
