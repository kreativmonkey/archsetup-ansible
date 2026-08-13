# sshd

Central role for the client side of SSH. It owns `~/.ssh`: the key pair and one
marked block per host in `~/.ssh/config`.

It deliberately does **not** manage the ssh agent — `gnome_keyring` owns that.

## Entry points

Install openssh, generate the key, apply the declared stanzas:

```yaml
- name: Configure ssh
  ansible.builtin.import_role:
    name: sshd
```

Generate a key pair only:

```yaml
- name: Generate an ssh key
  ansible.builtin.include_role:
    name: sshd
    tasks_from: keygen
  vars:
    sshd_user: sebastian
```

Add a host stanza — what other roles use:

```yaml
- name: Work around the host key rotation of a forge
  ansible.builtin.include_role:
    name: sshd
    tasks_from: add_host
  vars:
    sshd_host:
      name: git.example.org
      options:
        UpdateHostKeys: "no"
```

`keygen` sets `sshd_public_key`, so a playbook can hand the key to a forge
without reading the file out of this role's directory.

## Notes

- **This role was broken in three ways before.** `keygen.yml` read
  `git_user` — a variable of the `git` role — to build the path it slurped the
  public key from, so it failed outright without that role. `sshd_user` was the
  whole `system_users[0]` dict in one place and used as a name in another. And
  the agent task passed `scope: "{{ sshd_user.name }}"` to `systemd`, where
  `scope` only accepts `user`, `system` or `global`.
- **The agent belongs to `gnome_keyring`.** That role exports `SSH_AUTH_SOCK`,
  enables OpenSSH's `ssh-agent.socket` and disables `gcr-ssh-agent` for a
  documented reason. A second role enabling an agent for the same user is how
  "communication with agent failed" happens.
- **`add_host` validates with `ssh -G`** before the block is kept, so a typo in
  an ssh_config keyword fails the task instead of breaking every later `ssh`
  invocation for that user.
- **`openssh_keypair` never overwrites.** An existing key of the same type is
  left alone, so a key already deployed in an `authorized_keys` survives a run.
- **`community.crypto` is required** — `just setup` installs it from
  `requirements.yml`.
