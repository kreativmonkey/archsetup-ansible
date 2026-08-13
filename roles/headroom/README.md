# headroom

Runs the headroom context compression proxy as a systemd user service and tells
the agents on this host about it.

## What it does

| Area | How |
|------|-----|
| **Install** | `uv` from the repositories, `headroom-ai[all]` as a uv tool. |
| **Service** | `headroom.service`, a systemd **user** service on loopback. |
| **opencode** | Provider and MCP server registered through the `opencode` role. |
| **cursor** | RTK instructions as a marked block in `~/.cursorrules`. |
| **gemini** | Headroom memories as a marked block in `~/.gemini/GEMINI.md`. |

## Requirements

The play has to run while the target user is logged in — the `scope: user`
systemd tasks talk to that user's session bus.

## Example Playbook

```yaml
- name: Run the headroom proxy
  ansible.builtin.import_role:
    name: headroom
  vars:
    headroom_port: 8787
```

## Notes

- **The opencode config is not edited here any more.** This role used to run
  `ansible.builtin.replace` against `opencode.json`, matching `"provider": {`
  and pasting a JSON block in front of it. That file is rendered from a template
  by the `opencode` role, so the next opencode run silently threw the block
  away — and the regexp matched nothing as soon as the formatting changed. The
  provider and the MCP server go through `opencode`'s `add_provider` and
  `add_mcp_server` entry points now.
- **`uv tool install` always reports success**, so the role reads `uv tool list`
  first and only installs when the tool is missing. `headroom_force_reinstall`
  is there for an upgrade.
- **The `HEADROOM-MEMORIES` marker is deliberately unchanged.** A new marker
  string would leave the old block orphaned in `GEMINI.md` forever.
- **Both agent files belong to the user**, hence a marked `blockinfile` block
  instead of a template.
