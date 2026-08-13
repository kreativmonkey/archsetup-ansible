# editor

Central role for the default editor. It owns the `EDITOR` and `VISUAL` lines in
`/etc/environment`, installs the editor package, and adds the small amount of
extra setup the editors it knows need.

It manages **no editor configuration**. That is somebody else's: the Neovim
config comes from the `vim` role, which installs a distribution into
`~/.config/nvim`.

| `editor_default` | Extra setup |
|------------------|-------------|
| `helix`          | `hx` symlink, language servers from the repositories |
| `neovim`         | `vim-plug`, `vim-ansible` |
| `vim`            | `vim-plug`, `vim-ansible` |

Any other package name is installed and made the default, without extra setup.

## Parameters

`meta/argument_specs.yml` is the contract, `defaults/main.yml` the values.

## Example Playbook

```yaml
- name: Set the default editor
  ansible.builtin.import_role:
    name: editor
  vars:
    editor_default: neovim
```

## Notes

- **The package name and the command are different things.** The package is
  `neovim`, the binary is `nvim`, and `$EDITOR` needs the binary. The role used
  to do this with `editor_default | replace("neovim", "nvim")` in five places; it
  is a lookup table in `vars/main.yml` now.
- **The old `block`/`rescue` hunt is gone.** It searched all of `/etc` for stray
  `EDITOR=` assignments and, in the `rescue` path, looped over
  `search_editor_env.files` while writing `_found_editor_files.path` — two
  variables that exist nowhere in the role, next to a third,
  `_editor_found_files`, that was the actual loop variable. The rescue path
  could only ever fail with an undefined variable, which is why nobody noticed
  the role was doing nothing. `/etc/environment` is the file that decides
  `$EDITOR` for a login session, so that is the one the role owns.
- **`/etc/environment` is a plain `KEY=value` file**, not a shell script — no
  `export`, no expansion. It is read by `pam_env`, which is what makes `$EDITOR`
  apply to ssh, tty and the graphical session alike.
- **The editor packages themselves also come from `common`.** That is
  deliberate: `common` installs `helix` and `neovim` as part of the base set,
  this role only decides which one is *the default*. Installing the same package
  twice is free.
