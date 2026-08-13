# whisrs

Local voice dictation: whisrs listens for a hotkey, transcribes with a local
whisper model and types the result into whatever window has focus. Nothing
leaves the machine.

## What it does

| Area | How |
|------|-----|
| **Build** | `rust` from the repositories, whisrs itself with `cargo install --locked`. |
| **Typing** | `ydotool`, which needs `/dev/uinput` — the rule comes from the `udev` role. |
| **Hotkey** | Read through evdev, so the user joins `input` via the `system_user` role. |
| **Config** | `~/.config/whisrs/config.toml`. |
| **Service** | `whisrs.service` as a systemd **user** service. |

## Requirements

The play has to run while the target user is logged in — the `scope: user`
systemd tasks talk to that user's session bus.

## Example Playbook

```yaml
- name: Install voice dictation
  ansible.builtin.import_role:
    name: whisrs
  vars:
    whisrs_user: sebastian
    whisrs_language: de
```

## Notes

- **The udev rule and its reload belong to the `udev` role.** This role used to
  write `99-uinput.rules` itself and carried its own copy of the
  `udevadm control` / `udevadm trigger` handlers. Two roles reloading udev is one
  too many; `add_rule` notifies the central handler now.
- **Group membership takes effect on the next login.** Right after the first run
  the hotkey does not work yet, and that is not a broken install.
- **`cargo install` has no state-aware module.** It prints `Installed package` on
  a real install and `Ignored package … already installed` otherwise, which is
  the only handle `changed_when` has here.
- **`Super+Ctrl` is a modifier-only hotkey.** whisrs grabs it through evdev, so it
  works regardless of the compositor and needs no niri keybinding.
