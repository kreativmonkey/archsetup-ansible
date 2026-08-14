# aur

Central role for the Arch User Repository. It owns everything an AUR install
needs on this host and offers that as an entry point, so no other role has to
know how AUR packages get built.

## What it owns

| Area | How |
|------|-----|
| **Build prerequisites** | `base-devel` and `git` from the official repositories. |
| **Helper** | `aur_helper_package` (`yay` by default), built with `makepkg` because a helper cannot install itself. |
| **Build account** | `aur_build_user`, the unprivileged account `makepkg` runs as. |
| **Sudo rule** | `/etc/sudoers.d/zz-ansible-aur`, validated with `visudo` and probed afterwards. |
| **Entry point** | `install` — one or more packages, optionally with their own helper or build account. |

## Example Playbook

```yaml
- name: Establish AUR access
  ansible.builtin.import_role:
    name: aur
  vars:
    aur_packages:
      - visual-studio-code-bin
      - cheat
```

## Example: called from another role

```yaml
- name: Install the systemd-resolved hook from the AUR
  ansible.builtin.include_role:
    name: aur
    tasks_from: install
  vars:
    aur_package:
      name:
        - openvpn-update-systemd-resolved
```

## Parameters

`meta/argument_specs.yml` is the contract.

## The sudo rule, and why it is on by default

`makepkg` builds as an unprivileged user and then hands the result to
`pacman -U` **through sudo**. Ansible runs that build from a process with no
terminal, so a sudo rule that asks for a password has nothing to ask on:

```
sudo: no tty present and no askpass program specified
```

That is why `aur_sudoers_dropin` defaults to `true` and writes

```
sebastian ALL=(root) NOPASSWD: /usr/bin/pacman
```

**This makes the build account root-equivalent without a password.** `pacman`
installs arbitrary packages and runs their install hooks as root, so the rule is
not meaningfully narrower than full `NOPASSWD: ALL`. It buys unattended AUR
installs, and that is the whole trade. Set `aur_sudoers_dropin: false` if you
would rather type a password — the role then removes its drop-in again, and you
grant the right yourself or accept that AUR tasks fail.

## Notes

- **The helper is built with `makepkg`, not with a helper.** `use: makepkg`
  breaks the circle of needing an AUR helper to install an AUR helper. Every
  other install goes through `aur_helper`.
- **`yay` versus `yay-bin`.** `yay` is built from Go source and pulls in the
  toolchain to do it; `yay-bin` ships the same command prebuilt. Point
  `aur_helper_package` at `yay-bin` and leave `aur_helper` at `yay` — the first
  is the package, the second is the command. Do not switch an already installed
  variant to the other without removing it first, they conflict.
- **`install` establishes access itself.** It does not assume `main.yml` ran:
  a play reached with `--tags openvpn` never runs this role's own task, and
  without the sudo rule `makepkg` fails at the very last step — *after* a
  successful build — with `sudo: a terminal is required to read the password`.
  `__ensure/access.yml` is shared by both entry points and guarded by a fact, so
  it runs once per play however many roles ask for a package.
- **Pass lists, do not loop.** `kewlfft.aur.aur` resolves a whole list in one
  transaction and its documentation warns against `loop:`. That is why
  `main.yml` calls `install` once with all of `aur_packages` instead of once per
  package.
- **Validation before installation.** A syntax error in `/etc/sudoers.d` breaks
  sudo for every account, and `backup:` is no help because nothing would be left
  to run the restore with. Hence `validate: visudo -cf %s`.
- **The rule sorts last on purpose, and the role checks that it works.** sudo
  applies the **last** matching rule, not the most specific one, and reads
  `/etc/sudoers.d` alphabetically. A broad `%wheel ALL=(ALL:ALL) ALL` read after
  the exception silently takes it back — `sudo -l` still lists the exception, it
  just no longer wins, and the only symptom is `makepkg` failing minutes later
  with `sudo: a terminal is required to read the password`. Hence the `zz-`
  prefix (it has to beat `wheel` too, not just `99-`) and the probe right after
  writing the file, which fails the play with the actual diagnosis instead.
- **The `tuxedo` role still calls `kewlfft.aur.aur` inline.** It predates this
  role and was left untouched; moving it onto `install` would drop the duplicate
  `base-devel` task and the second copy of the build-user contract.
