# spice_client

Installs virt-viewer and makes `remote-viewer` the default application for
SPICE connection files (`.vv`, `application/x-virt-viewer`). In the Proxmox web
UI, *Console → SPICE* downloads such a file; the browser then opens it straight
into a SPICE session.

## Example Playbook

```yaml
- name: Set up the SPICE client
  ansible.builtin.import_role:
    name: spice_client
  vars:
    spice_client_users:
      - sebastian
```

## Notes

- **Two shared files, one key each.** `~/.config/mimeapps.list` and
  `~/.config/virt-viewer/settings` are also written by other programs —
  remote-viewer stores its per-VM monitor mapping in the latter — so the role
  sets single keys with `ini_file` instead of templating the files.
- **The VM side is not covered here.** SPICE needs `vga: qxl` (or
  `virtio`) on the Proxmox VM, and mouse integration and the clipboard need the
  SPICE vdagent in the guest. A `.vv` file is single-use and expires after a
  short time, so open it right after downloading.
- **No firewall change.** remote-viewer connects outbound to the Proxmox
  node's SPICE proxy on port 3128.
