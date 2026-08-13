<div align="center">

# archsetup-ansible

**My Arch Linux workstation, declared.**

One playbook, one host, one opinionated way of writing roles.

[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=flat-square&logo=archlinux&logoColor=white)](https://archlinux.org)
[![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=flat-square&logo=ansible&logoColor=white)](https://docs.ansible.com)
[![ansible-lint](https://img.shields.io/badge/ansible--lint-production-4B32C3?style=flat-square)](.ansible-lint)
[![Nix flake](https://img.shields.io/badge/Nix-flake-5277C3?style=flat-square&logo=nixos&logoColor=white)](flake.nix)
[![style: ansible-develop](https://img.shields.io/badge/style-ansible--develop-D97757?style=flat-square)](https://github.com/kreativmonkey/dotfiles/tree/main/dot_agents/skills/ansible-develop)

</div>

---

Arch only, `localhost` only. There is no `ansible_os_family` branching anywhere,
and package tasks call `community.general.pacman` directly instead of the
generic `package` module. What the machine *is* lives in
`host_vars/localhost.yml`; how it gets there lives in `roles/`.

## Quickstart

```console
nix develop     # dev shell: ansible, ansible-lint, yamllint, just
just setup      # install the collections from requirements.yml
just check      # what CI runs: ansible-lint --profile production + syntax check
just dry-run    # ansible-playbook --check
just run        # apply
just verify     # apply twice — the second run must report changed=0
```

> [!NOTE]
> The WireGuard tunnels resolve every value through Bitwarden, so `just run`
> wants an unlocked vault. Without one: `--skip-tags wireguard`.

## Layout

```
setup_workstation.yml     the workstation playbook — orchestration only
setup_git.yml             git configuration on its own
host_vars/localhost.yml   the host's data: accounts, identities, tunnels
requirements.yml          collections
roles/                    one role per owned piece of state
```

## Roles

<details>
<summary><b>Applied by <code>setup_workstation.yml</code></b> (in order)</summary>

| Role | What it does |
|---|---|
| `system_user` | local accounts, groups and subordinate id ranges |
| `pacman` | `/etc/pacman.conf` — output flags, parallel downloads, repositories |
| `common` | the base package set every host gets |
| `podman` | rootless containers, optionally as the docker replacement |
| `udev` | `/etc/udev/rules.d` and the reload |
| `firewalld` | firewalld with the nftables backend, `IPv6_rpfilter` |
| `wireguard` | one key pair and one `wg-quick` config per tunnel |
| `vim` | a Neovim distribution, switchable between two |
| `nix` | the nix package manager and `nix-daemon` |
| `direnv` | direnv hooked into fish and bash, plus nix-direnv |
| `cups` | printing, and the `cups` group membership |
| `gnome_keyring` | keyring and polkit agent for a niri (Wayland) session |
| `ollama` | ollama with a GPU acceleration backend |
| `opencode` | language servers and the rendered `opencode.json` |

</details>

<details>
<summary><b>Available, not wired into the playbook</b></summary>

| Role | What it does |
|---|---|
| `git` | git + lazygit, the `~/git/<forge>/` tree, per-forge identities — has its own playbook, `setup_git.yml` |
| `sshd` | the client side of SSH: `~/.ssh`, key pair, host entries |
| `sysctl` | `/etc/sysctl.d/60-ansible.conf` — called by others, never imported |
| `editor` | `EDITOR`/`VISUAL` in `/etc/environment` |
| `conky` | conky and its system-wide configuration |
| `headroom` | the headroom context compression proxy as a user service |
| `obs_studio` | obs-studio with what it needs on Wayland |
| `tuxedo` | TUXEDO hardware support (`tuxedo-drivers`, AUR) |
| `whisrs` | local voice dictation with a hotkey |

Enable one by adding an `import_role` task to the playbook — except `sysctl`,
which is a central role and is only ever reached through `include_role`.

</details>

## How this repo is written

The whole style comes down to one word: **ownership**. Almost every question
that comes up while writing a task is one of these three.

### 1. Who owns a piece of state? → that is a role

One role owns exactly one piece of state. Split when two states could plausibly
be rolled out independently; merge when a role would never sensibly run alone.

**Every role runs on its own.** No role relies on the playbook for privileges
or facts: `become: true` sits on the individual tasks, and a role that needs a
fact gathers it itself with a filtered, guarded `setup`. That is why the
playbooks carry neither `become` nor `gather_facts: true` — and why any role can
be lifted into a collection without dragging its play along.

### 2. Who owns a shared resource? → only the central role writes to it

Where a resource is shared, exactly one role owns it and everyone else calls its
entry points. Reading is free, writing is not.

| Central role | Owns | Entry points |
|---|---|---|
| `system_user` | accounts, groups, `/etc/subuid`, `/etc/subgid` | `add`, `add_group`, `add_to_group`, `add_subid` |
| `sysctl` | `/etc/sysctl.d/60-ansible.conf` | `set` |
| `udev` | `/etc/udev/rules.d`, the udev reload | `add_rule` |
| `sshd` | `~/.ssh`, `~/.ssh/config` | `keygen`, `add_host` |
| `git` | the global git configuration | `clone` |
| `opencode` | `opencode.json` | `add_provider`, `add_mcp_server` |
| `pacman` | `/etc/pacman.conf` | — |
| `firewalld` | `IPv6_rpfilter` in `firewalld.conf` | — |
| `editor` | `EDITOR`/`VISUAL` in `/etc/environment` | — |

Calling one looks like this — never a stray `lineinfile` in the calling role:

```yaml
- name: Grant GPU access to the ollama service account
  ansible.builtin.include_role:
    name: system_user
    tasks_from: add_to_group
  vars:
    system_user_membership:
      name: ollama
      groups: [render, video]
```

If a central role cannot do what you need, **extend the central role** — new
entry point, new `argument_specs` entry — and call it from outside. Not inline,
not even once.

### 3. Who owns a file? → that decides the module

| Ansible owns the file | Shared with the distribution or the user |
|---|---|
| drop-in directory or `ansible.builtin.template` | `lineinfile` / `blockinfile` |
| the whole file is ours to render | `regexp` on the **active** directive, never on a comment |

`validate:` wherever the tool offers one (`sshd -t -f %s`, `visudo -cf %s`);
`backup:` is not a substitute. `mode` is always an explicit string.

### The contract

`meta/argument_specs.yml` is the parameter contract — one entry per public
entry point, and the only place parameters are documented. Role READMEs carry
purpose and one example call per entry point, **never a parameter table**: that
would rot against the spec within a release.

Public parameters are prefixed with the role name
(`system_user_membership`, `opencode_mcp_server`, `git_repository`) — mostly as
dicts, so one call carries one record. A leading `__` means private — for
variables *and* for `tasks/__group/` directories, which must never be reached
with `tasks_from`.

### The gate

`ansible-lint --profile production` has to be green — that is what `just check`
runs and what enforces FQCN, task naming, `no-changed-when`, file permissions
and the role-prefix rule. yamllint runs embedded through the `yaml` rule.
Anything in `skip_list` needs a comment with a reason; without one, the code
gets fixed instead of the linter.

Idempotency is proven, not assumed: `just verify` applies twice and fails if the
second run reports anything but `changed=0`.

## Working with AI agents

The rules above are written down in full — including the task anatomy, the
naming conventions, the playbook rules and the list of hard prohibitions — in
the **`ansible-develop` skill**:

📖 **[ansible-develop](https://github.com/kreativmonkey/dotfiles/tree/main/dot_agents/skills/ansible-develop)**
— [`SKILL.md`](https://github.com/kreativmonkey/dotfiles/blob/main/dot_agents/skills/ansible-develop/SKILL.md) (the workflow and the rules)
· [`PATTERNS.md`](https://github.com/kreativmonkey/dotfiles/blob/main/dot_agents/skills/ansible-develop/PATTERNS.md) (full code patterns)
· [`COLLECTION.md`](https://github.com/kreativmonkey/dotfiles/blob/main/dot_agents/skills/ansible-develop/COLLECTION.md) (cutting roles into a collection)

It ships in my [dotfiles](https://github.com/kreativmonkey/dotfiles) and lands
in the shared agent config (`~/.agents/skills/`, symlinked into
`~/.claude/skills/` and the other CLI tools), so Claude Code, OpenCode, Gemini
CLI and Codex all load the same rules. **Any agent touching Ansible code in this
repository loads that skill first** — it is the reason the roles above all look
like they were written on the same afternoon.

Short version for a human reviewer: FQCN always · `become` per task, never on
the play · no bare `item`, `loop_var` is mandatory and prefixed · no bare
`setup:` · no `command`/`shell` without `creates`/`removes`/`changed_when` · no
`dependencies:` in `meta/main.yml` · no `tasks_from` from a playbook · no
`template` on a file Ansible does not own.

## Nothing infrastructure-specific in here

This repository is public. Addresses, DNS servers, internal domains and keys
belong in a lookup, not in a role or a template.

`roles/wireguard` is the example: it ships a generic `interface.conf.j2` and no
interface of its own, and `host_vars/localhost.yml` pulls every identifying
value of a tunnel from a single Bitwarden item.

```yaml
address: "{{ lookup('community.general.bitwarden', 'WireGuard pudelab', field='Address') | first }}"
```
