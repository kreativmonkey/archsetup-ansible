# vim

Installs one of two Neovim distributions and switches cleanly between them.

| `vim_distro` | Config starter | How |
|--------------|----------------|-----|
| `astronvim`  | [AstroNvim/template](https://github.com/AstroNvim/template) | git clone |
| `lazyvim`    | [LazyVim/starter](https://github.com/LazyVim/starter)       | git clone |

Both ship a plain config starter that is cloned into `~/.config/nvim`. The
upstream `.git` is dropped, so the config becomes your own.

Everything comes from the official Arch repositories — no AUR, no upstream
installer script.

## Parameters

`meta/argument_specs.yml` is the contract, `defaults/main.yml` the values.

## Example Playbook

```yaml
- name: Install a Neovim distribution
  ansible.builtin.import_role:
    name: vim
  vars:
    vim_distro: lazyvim
```

## Switching distributions

Re-run the role with a different `vim_distro`. Before installing,
`~/.config/nvim` and the shared Neovim state (`~/.local/share/nvim`,
`~/.local/state/nvim`, `~/.cache/nvim`) are removed so no leftovers of the
previous distribution remain. Legacy LunarVim and SpaceVim paths
(`~/.config/lvim`, `~/.SpaceVim`, `~/.SpaceVim.d` and their state/cache dirs)
are cleaned up too.

All distributions start via `nvim`.

## Idempotency

The install is destructive, so it must not run twice. The role records the
distribution it installed in `~/.config/nvim/.ansible_vim_distro` and rebuilds
only when that marker does not match `vim_distro`:

| Situation | What happens |
|-----------|--------------|
| Marker matches `vim_distro` | Nothing. Dependencies are still checked, everything else is skipped. |
| Marker differs | Backup, cleanup, fresh install, marker rewritten. |
| No marker | Treated as a switch — see the note below. |
| `vim_force_reinstall: true` | Rebuild regardless of the marker. |

The marker lives *inside* the config directory on purpose: delete
`~/.config/nvim` by hand and the role reinstalls on the next run, which is
what you want from a repair.

Without this the role rebuilds on every play, and each rebuild costs you the
installed plugins (`~/.local/share/nvim`), the pinned `lazy-lock.json` and any
edit you made under `lua/`. The marker is written last, so a failed clone
leaves none behind and the next run retries.

**A configuration that predates the marker triggers exactly one rebuild.** It
cannot be told apart from a switch. If the installed distribution is already
the one you want and you would rather keep it, write the marker by hand before
the first run:

```console
echo lazyvim > ~/.config/nvim/.ansible_vim_distro
```

## Backups

`~/.config/nvim.back` is replaced whenever a rebuild happens, so it holds the
generation from immediately before the *last* rebuild — not the configuration
you started out with. The backup keeps its own marker file, so
`cat ~/.config/nvim.back/.ansible_vim_distro` tells you which distribution is
in there. Keep anything you actually care about somewhere else.

## Notes

- **`nodejs` is installed separately from the dependency list.** Providers like
  `nodejs-lts-jod` both provide and conflict with `nodejs`, so listing it
  outright would force-replace an installed LTS under `--noconfirm`. The role
  asks `pacman -T nodejs` first.
- **`vim_starter_version` defaults to `HEAD`**, which means the starter is
  whatever upstream ships today. Pin it to a tag if you want the config
  reproducible.
- **NvChad, SpaceVim and LunarVim were dropped.** NvChad's starter still exists,
  but SpaceVim and LunarVim only support their own installer scripts — a
  `curl | bash` this role cannot make idempotent. Their paths are still in the
  cleanup list so an existing install is removed on migration.
