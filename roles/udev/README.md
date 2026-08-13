# udev

Central role for udev rules. It owns `/etc/udev/rules.d` and the reload — no
other role writes a rule file or calls `udevadm`.

`whisrs` used to write `99-uinput.rules` itself and carried its own copy of the
reload/trigger handlers. It calls `add_rule` now, and the `Reload udev` handler
here fires for it.

## Entry points

The rules declared for the host:

```yaml
- name: Install udev rules
  ansible.builtin.import_role:
    name: udev
```

A single rule, which is what service roles use:

```yaml
- name: Allow the input group to write to uinput
  ansible.builtin.include_role:
    name: udev
    tasks_from: add_rule
  vars:
    udev_rule:
      name: 99-uinput.rules
      content: |
        KERNEL=="uinput", MODE="0660", GROUP="input"
```

## Notes

- **One file per rule.** A rule can be withdrawn on its own, and two roles
  never end up editing the same file.
- **The numeric prefix is the sort order**, so it belongs in `name`.
- **`udevadm` always reports changed.** There is no state to compare against —
  the reload *is* the effect. Notifying the handler only when a rule file
  actually changed is what keeps a run quiet.
- **A rule that only relaxes permissions needs a trigger to take effect on
  devices that are already present**, which is why `Reload udev` chains into
  `Trigger udev`.
