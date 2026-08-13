# pacman

Central role for `/etc/pacman.conf`. It owns the output flags,
`ParallelDownloads` and which repositories are enabled — no other role edits
that file.

It also installs a hardened weekly `paccache` timer, because
`/var/cache/pacman/pkg` otherwise grows without bound.

## Example Playbook

```yaml
- name: Configure pacman and its repositories
  ansible.builtin.import_role:
    name: pacman
  vars:
    pacman_parallel_downloads: 10
    pacman_repos:
      - core
      - extra
      - multilib
```

## Notes

- **Single directives, never a template.** `pacman.conf` belongs to the pacman
  package as much as to Ansible and gets a `.pacnew` on update. Every `regexp`
  targets the active line, never a commented example.
- **Enabling a repository takes a `replace`, not a `lineinfile`.** The section
  header and its `Include = /etc/pacman.d/mirrorlist` ship commented out
  together, so they have to be uncommented in one go. Two separate lines would
  leave a repository without its mirrorlist.
- **The flags follow their toggle.** `pacman_color: false` removes the `Color`
  line instead of leaving it in place — `state` is derived from the boolean.
- **`Update the pacman cache` is a handler for a reason.** A freshly enabled
  repository has no package list yet, so the next role that installs from it
  would fail with "target not found".
- **`flush_handlers` before enabling the timer**: systemd cannot enable a unit
  it has not read yet.
- **`community` was dropped from `pacman_repos`.** Arch merged that repository
  into `extra` in 2023, so the shipped `pacman.conf` has no `#[community]`
  section left for the `replace` to match — the entry was a silent no-op.
