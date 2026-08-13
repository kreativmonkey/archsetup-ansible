# tuxedo

Installs the TUXEDO hardware support on Arch: the `tuxedo-drivers` and
`tuxedo-yt6801` DKMS kernel modules and the TUXEDO Control Center, plus its
`tccd` daemon.

Only useful on TUXEDO hardware, which is why it is not part of
`setup_workstation.yml`.

## Requirements

- The `kewlfft.aur` collection — `just setup` installs it from
  `requirements.yml`. It is **not** bundled with the `ansible` package.
- `tuxedo_build_user` must be able to run `pacman` through `sudo` without a
  password, or have an AUR helper (`yay`, `paru`) already installed. `makepkg`
  builds as that user and then hands the built package to pacman.

## Example Playbook

```yaml
- name: Install the TUXEDO hardware support
  ansible.builtin.import_role:
    name: tuxedo
  vars:
    tuxedo_build_user: sebastian
```

## Notes

- **`ansible.builtin.aur` does not exist.** The role used to call it, so it
  failed at parse time on every run (`syntax-check[unknown-module]`) — and its
  `name:` was empty with the package list in an unrelated `loop`, so it could
  never have installed anything either.
- **AUR builds must not run as root.** `makepkg` aborts outright, hence
  `become_user: "{{ tuxedo_build_user }}"` instead of plain `become: true`.
- **DKMS modules are rebuilt on a kernel update** by the pacman hook, not by
  this role.
- **`use: auto`** picks an installed AUR helper if there is one and falls back
  to plain `makepkg`.
