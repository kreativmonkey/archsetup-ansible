# fonts

Owns which fonts exist on this host and which of them applications reach for by
default: the corporate typeface from the brand guide, the patched nerd fonts a
terminal needs, and `/etc/fonts/local.conf`.

## Example Playbook

```yaml
- name: Install the fonts
  ansible.builtin.import_role:
    name: fonts
  vars:
    fonts_nerd_packages:
      - ttf-firacode-nerd
      - ttf-nerd-fonts-symbols-mono
    fonts_default_monospace: FiraCode Nerd Font Mono
```

## Notes

- **The corporate set is not a parameter.** <https://www.puzzle.ch/brand>
  specifies Roboto, and that is not a per-host decision — it sits in
  `vars/main.yml` as `__fonts_corporate_packages`, the way `common` treats its
  base set. `ttf-roboto` carries the regular family *and* Roboto Condensed.
- **Roboto Slab is missing on purpose.** The brand page names it, Arch does not
  package it, and the only source is a zip under an unversioned WordPress
  upload path. If it is ever needed, it belongs here as a pinned
  `get_url` + `unarchive` into `/usr/local/share/fonts` — not as a silent
  download that changes under the host.
- **Nerd fonts come from `extra`, not the AUR.** The whole `ttf-*-nerd` /
  `otf-*-nerd` family is packaged officially, so `community.general.pacman` is
  enough and no build user is involved.
- **No `fc-cache` task.** Every font here arrives through pacman, whose
  fontconfig hook rebuilds the cache as part of the transaction. A handler
  would fire on top of work that already happened. Fonts dropped in as plain
  files would need one — that is the moment to add it.
- **`local.conf`, not a `conf.d` drop-in.** fontconfig reserves
  `/etc/fonts/local.conf` for the local system and no package ships one, so
  this role owns the file outright. `/etc/fonts/conf.d/` is the opposite: it is
  a directory of symlinks that packages maintain.
- **Family names, not package names.** `fonts_default_monospace` is what
  `fc-list : family` prints — `JetBrainsMono Nerd Font Mono`, not
  `ttf-jetbrains-mono-nerd`. A typo here fails silently: fontconfig just falls
  through to its own ranking.
- **`match` + `binding="strong"`, not `alias` + `prefer`.** The usual
  `<alias><prefer>` snippet does work for `sans-serif` but *not* for
  `monospace`: `51-local.conf` loads this file before `60-latin.conf`, whose own
  monospace alias then wins, and the generic keeps resolving to Noto Sans Mono
  without a word of complaint. The template uses a strong prepend instead.
- **`fonts_default_monospace` must be a family this role installs.** The symbol
  fallback is bound strongly so nerd glyphs always come from one known font
  instead of whichever nerd font fontconfig ranks first. The price: name a
  family that is not installed and the icon-only font moves up to first place —
  every character without a glyph in it turns into a box. Setting
  `fonts_symbol_fallback: ""` removes that edge, at the cost of the
  deterministic icon source.
- **No `validate:` on the template.** fontconfig ships no config checker;
  `fc-validate` checks fonts, not configuration. After a run:

  ```
  fc-match monospace                  # -> the family in fonts_default_monospace
  fc-match sans-serif                 # -> the family in fonts_default_sans
  fc-match 'monospace:charset=f09b'   # -> the symbol fallback
  ```
