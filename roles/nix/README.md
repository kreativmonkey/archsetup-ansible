# nix

Installs the nix package manager, starts `nix-daemon`, puts the configured users
into the `nix-users` group and sets `max-jobs`.

This is what makes the `nix develop` dev shells of every project on this host
work.

## Example Playbook

```yaml
- name: Install the nix package manager
  ansible.builtin.import_role:
    name: nix
  vars:
    nix_users:
      - sebastian
```

## Notes

- **`/etc/nix/nix.conf` is shared with pacman**, which updates the file on every
  nix release. That is why the role owns a single `max-jobs` line via
  `lineinfile` instead of templating the file — the `regexp` targets the active
  directive, never a commented example.
- **`max-jobs = auto`** is one build job per core. Nix's own default of `1`
  leaves most of the machine idle during a build.
- **The `nix-users` membership goes through `system_user`**, the role that owns
  groups.
