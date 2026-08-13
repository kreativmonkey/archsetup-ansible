# git

Installs git plus `lazygit`, lays out the `~/git/<forge>/` project tree and
manages the **global** git configuration: a set of modern defaults, aliases, a
global gitignore, and one identity per forge folder wired up with `includeIf`.

## What it does

| Area | How |
|------|-----|
| **Packages** | `git`, `lazygit`. `git-delta` and `meld` come from the `common` role. |
| **Project tree** | One directory per forge under `git_base.dir` (`~/git/github.com`, …) from `git_identities[*].folder`. |
| **Global config** | `~/.gitconfig` from `git_settings` / `git_settings_extra` / `git_aliases` (see *Defaults* below). |
| **Identities** | `~/git/<folder>/.gitconfig` per entry in `git.config`, activated by `[includeIf "gitdir:~/git/<folder>/"]` in the global config. Optional per-identity SSH key and commit signing. |
| **Global gitignore** | `~/.config/git/ignore` from `git_global_ignore` — git's XDG default path, no `core.excludesFile` needed. |

Both managed files are written with `backup: true`, so a hand-written predecessor
ends up next to it as `.gitconfig.<timestamp>~`.

## Parameters

`meta/argument_specs.yml` is the contract, `defaults/main.yml` the values.

### Identity entries

```yaml
git_identities:
  - folder: github.com
    name: Kreativmonkey
    email: kreativmonkey@calyrium.org
    # optional:
    ssh_key: ~/.ssh/id_ed25519_github     # core.sshCommand + IdentitiesOnly
    signing_key: ~/.ssh/id_ed25519_github.pub
    signing_format: ssh                   # default: ssh
    settings:                             # anything else, same shape as git_settings
      pull:
        rebase: false
```

`signing_key` enables `commit.gpgsign` and `tag.gpgsign` for that folder only.

### Adding a setting from the inventory

```yaml
git_settings_extra:
  core:
    pager: less        # replaces delta
  url "git@github.com:":
    insteadOf: https://github.com/
```

## Defaults, and why

| Setting | Reason |
|---------|--------|
| `init.defaultBranch = main` | `master` is only still the built-in default for backwards compatibility. |
| `push.autoSetupRemote`, `push.followTags`, `push.default = simple` | First push needs no `--set-upstream`; annotated tags travel with their commits. |
| `pull.rebase`, `rebase.autoStash/autoSquash/updateRefs` | Linear history, rebase works with a dirty tree, `fixup!` commits are applied, and dependent local branches are moved along (git ≥ 2.38). |
| `fetch.prune/pruneTags/all` | Deleted upstream branches and tags disappear locally too. |
| `diff.algorithm = histogram`, `colorMoved = zebra`, `colorMovedWS`, `mnemonicPrefix`, `renames = copies` | Readable hunks, moved code distinguishable from new code, reindents not shown as rewrites. |
| `merge.conflictstyle = zdiff3` | Keeps common context out of the conflict markers (git ≥ 2.35). |
| `rerere.enabled/autoUpdate` | Records conflict resolutions and replays them — the main reason repeated rebases stop hurting. |
| `credential.helper = git-credential-libsecret` | HTTPS tokens land in the Secret Service (`gnome-keyring` role) instead of plaintext `~/.git-credentials`. |
| `core.pager = delta` + `interactive.diffFilter` + `[delta]` | Syntax-highlighted diffs with `n`/`N` navigation. |
| `worktree.guessRemote` | `git worktree add <path> <branch>` sets up remote tracking — matches the one-task-one-worktree workflow. |
| `commit.verbose`, `log.date = iso`, `column.ui`, `branch.sort`, `tag.sort`, `help.autocorrect = prompt` | Quality of life. |
| `transfer.fsckObjects` | Validates objects on transfer. **Flip this off** if cloning an old, malformed repository aborts with an fsck error. |

Deliberately *not* set: commit signing globally (per identity instead),
`core.excludesFile` (the XDG default already points at the managed file), and
`git maintenance` (needs per-repository registration).

## Entry points

The configuration and the project tree:

```yaml
- name: Configure git
  ansible.builtin.import_role:
    name: git
```

Clone a single repository:

```yaml
- name: Clone the dotfiles
  ansible.builtin.include_role:
    name: git
    tasks_from: clone
  vars:
    git_repository: git@github.com:kreativmonkey/dotfiles.git
```

## Notes

- **The trailing slash in `includeIf` is load-bearing.** `gitdir:~/git/github.com`
  matches nothing, because git only appends `**` to a pattern that ends in `/`.
  Without it the include never fires and commits silently use the global
  identity. Verify with `git -C ~/git/<folder>/<repo> config user.email`.
- **Linked worktrees** inherit the identity as long as the *main* checkout lives
  under `~/git/<folder>/` — matching happens on the git dir, which for a linked
  worktree points back into the main repository.
- **Do not keep a second global config.** Git reads `$XDG_CONFIG_HOME/git/config`
  *and* `~/.gitconfig`, with the latter winning. If you move `git_global_config`
  to the XDG path, delete `~/.gitconfig`.
- **`tasks/clone.yml` works now.** It used to reference `git_base_dir`,
  `git_base_folder` and `git_base_owner` — three variables that do not exist
  anywhere in the role — and its loop was commented out in `main.yml`, which is
  the only reason nobody noticed. It derives the forge from the URL and handles
  `https://`, `ssh://` and `git@host:path` alike.
- **`git.config` became `git_identities`, `git.repositorys` became
  `git_repositories`.** The unprefixed `git` dict is what `ansible-lint` flags as
  `var-naming[no-role-prefix]`, and a variable called `git` next to a role called
  `git` reads badly everywhere it appears.
- **The `ssh.gitlab.puzzle.ch` workaround is no longer a commented-out TODO.**
  `git_ssh_hosts` is handed to the `sshd` role, which owns `~/.ssh/config` and
  validates the result with `ssh -G`. Declare the host in the inventory, not in
  the role.
