# sysctl

Central role for kernel parameters. It owns `/etc/sysctl.d/60-ansible.conf` —
no other role calls `ansible.posix.sysctl` or writes into `/etc/sysctl.d`.

`podman` (`kernel.unprivileged_userns_clone`) and `wireguard`
(`net.ipv4.ip_forward`) both used to set parameters themselves, one of them
through the deprecated `ansible.builtin.sysctl` redirect.

A drop-in rather than `/etc/sysctl.conf`: the distribution file and the vendor
files under `/usr/lib/sysctl.d` stay untouched, and withdrawing a setting is a
`state: absent` instead of a hand edit.

## Entry points

Host level parameters from the inventory:

```yaml
- name: Apply the kernel parameters
  ansible.builtin.import_role:
    name: sysctl
  vars:
    sysctl_settings:
      - name: vm.swappiness
        value: 10
```

A single parameter, which is what service roles use:

```yaml
- name: Enable IPv4 forwarding for the tunnel
  ansible.builtin.include_role:
    name: sysctl
    tasks_from: set
  vars:
    sysctl_setting:
      name: net.ipv4.ip_forward
      value: 1
```

## Notes

- **`ansible.posix.sysctl`, not `ansible.builtin.sysctl`.** The latter is a
  redirect into this collection and `ansible-lint` flags it as non-canonical.
- **The module writes and applies in one step** (`sysctl_set: true`,
  `reload: true`), so there is no reload handler to notify.
- **`sysctl_set: true` fails on a parameter the running kernel does not
  expose.** That is deliberate: a persisted setting that silently never applies
  is worse than a failed play.
