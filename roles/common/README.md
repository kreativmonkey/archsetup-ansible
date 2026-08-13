# common

Installs the base package set every host in this setup gets: editors, terminal
tooling, backup, networking and office packages.

The set itself lives in `vars/main.yml` as `__common_packages` — internal,
because the set is what the role *is*. Per-host additions go through
`common_custom_packages`.

## Example Playbook

```yaml
- name: Install the base package set
  ansible.builtin.import_role:
    name: common
  vars:
    common_custom_packages:
      - wireshark-qt
```

## Notes

- **`community.general.pacman`, not `ansible.builtin.package`.** Everything here
  is Arch-only, and the explicit module needs no `ansible_pkg_mgr` fact — which
  is what lets the role run without a fact-gathering play.
- **One transaction for the whole set.** Installing package by package in a loop
  is slower and makes pacman resolve dependencies repeatedly.
- **AUR packages are out of scope.** `visual-studio-code-bin`, `cheat`, `ventoy`
  and `libreoffice-fresh-de` are named in `vars/main.yml` so the gap is
  visible; the `tuxedo` role shows the AUR pattern if you need it.
