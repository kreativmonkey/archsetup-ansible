# archsetup-ansible

Ansible setup for an Arch Linux workstation. Arch only, `localhost` only —
there is no `ansible_os_family` branching anywhere, and package tasks call
`community.general.pacman` directly rather than the generic `package` module.

## Usage

```console
nix develop          # dev shell: ansible, ansible-lint, yamllint, just
just setup           # install the collections from requirements.yml
just check           # what CI runs: ansible-lint + syntax check
just dry-run         # ansible-playbook --check
just run             # apply
just verify          # apply twice, second run must report changed=0
```

## Layout

```
setup_workstation.yml   the workstation playbook
setup_git.yml           git configuration on its own
host_vars/localhost.yml the host's data — users, identities, tunnels
requirements.yml        collections
roles/                  one role per owned piece of state
```

## Conventions

**Every role runs on its own.** No role relies on the playbook for privileges
or facts: `become: true` sits on the individual tasks, and a role that needs a
fact gathers it itself with a filtered, guarded `setup`. That is why the
playbooks carry neither `become` nor `gather_facts: true`.

**One role owns one piece of state.** Where a resource is shared, exactly one
role owns it and the others call its entry points instead of writing to it:

| Central role | Owns | Entry points |
|--------------|------|--------------|
| `system_user` | accounts, groups, `/etc/subuid`, `/etc/subgid` | `add`, `add_group`, `add_to_group`, `add_subid` |
| `sysctl` | `/etc/sysctl.d/60-ansible.conf` | `set` |
| `udev` | `/etc/udev/rules.d`, the udev reload | `add_rule` |
| `sshd` | `~/.ssh`, `~/.ssh/config` | `keygen`, `add_host` |
| `pacman` | `/etc/pacman.conf` | — |
| `firewalld` | `IPv6_rpfilter` in `firewalld.conf` | — |
| `git` | the global git configuration | `clone` |
| `opencode` | `opencode.json` | `add_provider`, `add_mcp_server` |
| `editor` | `EDITOR`/`VISUAL` in `/etc/environment` | — |

Calling one looks like this:

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

**`meta/argument_specs.yml` is the parameter contract**, one entry per public
entry point, and the only place parameters are documented — a README table
would rot against it. Task files under `tasks/__*/` are private and must not be
reached with `tasks_from`.

**Configuration files follow ownership.** Ansible owns the file → drop-in or
`template`. Shared with the distribution or the user → `lineinfile` /
`blockinfile` against the active directive, with `validate:` wherever the tool
offers it.

## Nothing infrastructure-specific in this repository

This repo is public. Addresses, DNS servers, internal domains and keys belong in
a lookup, not in a role or a template. `roles/wireguard` is the example: it
ships a generic `interface.conf.j2` and no interface of its own, and
`host_vars/localhost.yml` pulls every identifying value of a tunnel from a
single password-manager item.
