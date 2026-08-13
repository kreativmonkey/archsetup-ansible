# cups

Installs and starts cups and puts the configured users into the `cups` group so
they can add and configure print queues.

## Example Playbook

```yaml
- name: Configure printing
  ansible.builtin.import_role:
    name: cups
  vars:
    cups_users:
      - sebastian
```

## Notes

- **The group membership goes through `system_user`.** Five roles add groups to
  the same account; only the central role's `append: true` keeps them from
  overwriting each other.
- **Group membership takes effect on the next login**, not when this role runs.
- **No handler.** This role manages no cups configuration file, so there is
  nothing a restart could pick up — the previous `Restart cups` handler fired on
  a group change, which cups does not read at runtime anyway.
