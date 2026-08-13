# direnv

Installs direnv, hooks it into fish and bash, and installs the nix-direnv
`direnvrc` so `use flake` gets a cache — dev shells then survive a
`nix-collect-garbage` and load without rebuilding.

## Example Playbook

```yaml
- name: Configure direnv
  ansible.builtin.import_role:
    name: direnv
  vars:
    direnv_users:
      - sebastian
```

## Notes

- **fish gets a `conf.d` drop-in, bash gets a managed line.** fish has a
  drop-in directory, so this role owns `conf.d/direnv.fish` outright. `.bashrc`
  has none and belongs to the user, so a single `lineinfile` is the most the
  role may take.
- **`direnv_nix_direnv_version` is pinned.** There is no Arch package for
  nix-direnv, so the `direnvrc` comes from GitHub. Pointing at a branch would
  let upstream change the behaviour of every dev shell on this host without a
  commit anywhere.
- **The per-user work lives in `tasks/__configure/user.yml`.** Private include,
  looped once per user — that beats six loops over the same list.
