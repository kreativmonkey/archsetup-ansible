vim
===

Installs a single Neovim distribution on Arch Linux and lets you switch
between them. Switching is destructive by design: every other distribution's
files are removed first, so exactly one distribution is ever present.

Supported distributions
------------------------

| `vim_distro` | Source | Installed via |
|--------------|--------|---------------|
| `astronvim`  | [AstroNvim/template](https://github.com/AstroNvim/template) | git clone |
| `lazyvim`    | [LazyVim/starter](https://github.com/LazyVim/starter)       | git clone |
| `nvchad`     | [NvChad/starter](https://github.com/NvChad/starter)         | git clone |
| `spacevim`   | [SpaceVim](https://spacevim.org)                            | upstream installer |
| `lunarvim`   | [LunarVim](https://www.lunarvim.org)                        | upstream installer |

AstroNvim, LazyVim and NvChad provide a plain config starter that is cloned
into `~/.config/nvim` (the upstream `.git` is dropped so it becomes your own
config). SpaceVim and LunarVim ship no standalone config repo — upstream only
supports their installer scripts, so those are run non-interactively.

Requirements
------------

- Arch Linux (uses `pacman` via `ansible.builtin.package`).
- `system_users` defined (the first user is the default install target).

All optional dependencies are installed from the official Arch repositories
(no AUR): ripgrep, fd, fzf, lazygit, tree-sitter-cli, the gcc/make build
toolchain, nodejs/npm, python + python-pynvim, go, rust, X11/Wayland clipboard
providers, Nerd Fonts, the lua/bash/yaml language servers, and image preview
helpers. See `vars/main.yml` for the full list.

Role Variables
--------------

| Variable      | Default                  | Description |
|---------------|--------------------------|-------------|
| `vim_distro`  | `lazyvim`                | Distribution to install: `astronvim`, `lazyvim`, `nvchad`, `spacevim`, `lunarvim`. |
| `vim_user`    | `{{ system_users[0].name }}` | User the distribution is installed for. |
| `vim_backup`  | `true`                   | Copy an existing `~/.config/nvim` to `~/.config/nvim.back` before removal. |

Switching distributions
------------------------

Re-run the role with a different `vim_distro`. Before installing, these paths
are removed so no leftovers of the previous distribution remain: `~/.config/nvim`,
`~/.config/lvim`, `~/.SpaceVim`, `~/.SpaceVim.d`, and the shared Neovim state
(`~/.local/share/nvim`, `~/.local/state/nvim`, `~/.cache/nvim`) plus the
LunarVim equivalents and its `~/.local/bin/lvim` launcher.

Note: `lunarvim` starts via the `lvim` command (`~/.local/bin` must be on
`PATH`), `spacevim` and the git-clone distros start via `nvim`.

Example Playbook
----------------

```yaml
- hosts: localhost
  become: true
  roles:
    - role: vim
      vars:
        vim_distro: nvchad
```

License
-------

MIT
