# podman

Installs podman, sets up rootless containers and can replace docker with
`podman-docker`.

## What it does

| Area | How |
|------|-----|
| **Packages** | `podman`, plus `fuse-overlayfs` and `slirp4netns` for rootless. |
| **Cockpit** | `cockpit-podman`, but only when cockpit is already installed — decided from the package facts, not assumed. |
| **User namespaces** | `kernel.unprivileged_userns_clone` through the `sysctl` role. |
| **Subordinate ids** | One `/etc/subuid` and `/etc/subgid` line per user through the `system_user` role, followed by `podman system migrate`. |
| **Docker** | Optional: stop and remove docker, install `podman-docker`. |

## Example Playbook

```yaml
- name: Install podman
  ansible.builtin.import_role:
    name: podman
  vars:
    podman_rootless: true
    podman_rootless_users:
      - sebastian
```

## Notes

- **The role no longer writes sysctl or subuid/subgid itself.** Both are shared
  resources: `wireguard` also sets kernel parameters, and `useradd`, `usermod`
  and podman all write the subordinate id files. They belong to `sysctl` and
  `system_user`.
- **`podman system migrate` is guarded by a fact, not by `is changed`.** The
  change happens inside `system_user`, so the central role reports it as
  `system_user_subid_changed` and this role reacts to that. A handler cannot be
  notified across a role boundary in that direction.
- **Rootless needs the full 65536 id range.** With a smaller one, every image
  that uses a non-root user fails to start.
- **`podman_replace_docker` is off by default** because it uninstalls a package.
  docker and `podman-docker` both provide `/usr/bin/docker` and cannot coexist,
  and the docker service is stopped first so pacman does not pull the daemon out
  from under running containers.
