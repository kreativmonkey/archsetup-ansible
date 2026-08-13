# conky

Installs conky, writes the system wide configuration to `/etc/conky/conky.conf`
and drops an XDG autostart entry so it starts with the graphical session.

## Example Playbook

```yaml
- name: Install conky
  ansible.builtin.import_role:
    name: conky
  vars:
    conky_users:
      - sebastian
```

## Notes

- **The config is system wide, the autostart entry is per user.** Conky reads
  `/etc/conky/conky.conf` when started without `-c`, so one file serves every
  user while each still decides whether it starts.
- **The role gathers its own facts.** The template puts `ansible_hostname` into
  the config, so `tasks/main.yml` runs a filtered `setup` guarded on that fact
  instead of assuming the play gathered it.
- **`X-GNOME-Autostart-Delay=10`** in `files/conky.desktop` is what keeps conky
  from starting before the compositor has a screen to draw on.
