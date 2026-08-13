# system_user

Central role for local accounts, groups and subordinate id ranges. It owns
`/etc/passwd`, `/etc/group`, `/etc/subuid` and `/etc/subgid` — no other role
calls `ansible.builtin.user` or `ansible.builtin.group`.

Five roles used to append group memberships to the same account on their own
(`cups`, `nix`, `obs_studio`, `whisrs`, `ollama`), and `podman` wrote the
subordinate id files. Whoever ran last decided the outcome. They all go through
the entry points below now.

Every write appends. This role only knows what the inventory declares, so it
must never replace a group list — `wheel`, `video` or anything granted outside
Ansible has to survive a run.

## Entry points

Apply everything the inventory declares:

```yaml
- name: Apply the declared users and groups
  ansible.builtin.import_role:
    name: system_user
```

Create one account:

```yaml
- name: Create the build account
  ansible.builtin.include_role:
    name: system_user
    tasks_from: add
  vars:
    system_user_account:
      name: build
      group: build
      shell: /bin/bash
```

Create a group:

```yaml
- name: Create the cups group
  ansible.builtin.include_role:
    name: system_user
    tasks_from: add_group
  vars:
    system_user_group:
      name: cups
      system: true
```

Put a user into groups — what service roles need:

```yaml
- name: Grant GPU access to the ollama service account
  ansible.builtin.include_role:
    name: system_user
    tasks_from: add_to_group
  vars:
    system_user_membership:
      name: ollama
      groups:
        - render
        - video
```

Reserve a subordinate id range for rootless containers:

```yaml
- name: Reserve the subordinate ids for rootless podman
  ansible.builtin.include_role:
    name: system_user
    tasks_from: add_subid
  vars:
    system_user_subid:
      name: "{{ podman_rootless_user }}"
```

`add_subid` sets `system_user_subid_changed`, so the caller can refresh its own
cache of the range:

```yaml
- name: Propagate the ranges into the podman user storage
  ansible.builtin.command:
    cmd: podman system migrate
  when: system_user_subid_changed | default(false)
```

## Notes

- **`add` takes dicts, `add_to_group` takes names.** `add` mirrors the
  inventory shape (`groups: [{name: cups}]`) so it can loop over
  `system_users` unchanged. `add_to_group` is the short form for service roles
  (`groups: [video, render]`). Both are in `meta/argument_specs.yml`.
- **The primary group defaults to the login name**, which is what `useradd -U`
  does on Arch.
- **No passwords.** Accounts here are created without one; the workstation user
  already exists and its password is not Ansible's business.
