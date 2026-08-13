# obs_studio

Installs obs-studio with what it needs on Wayland — the Qt platform plugins and
`v4l2loopback-dkms` for the virtual camera — and grants the configured users
access to the camera device.

## Example Playbook

```yaml
- name: Install obs-studio
  ansible.builtin.import_role:
    name: obs_studio
  vars:
    obs_studio_users:
      - sebastian
```

## Notes

- **The virtual camera is a `/dev/video*` node owned by the `video` group**, so
  "Start Virtual Camera" only works for a member of that group. The membership
  goes through `system_user`.
- **`v4l2loopback-dkms` builds against the running kernel.** After a kernel
  update the module is rebuilt by the dkms pacman hook, not by this role.
- The role was called `obs-studio`. A hyphen is not a legal Ansible role name
  (`role-name` in `ansible-lint`), hence `obs_studio`.
