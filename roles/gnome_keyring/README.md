# gnome_keyring

Sets up GNOME Keyring and its companions for a **niri** (Wayland) session on Arch
Linux, so that a non-GNOME compositor gets the same secrets/SSH/polkit experience
GNOME ships out of the box.

**This role owns the user's ssh-agent.** The `sshd` role generates keys; it does
not touch the agent. Two roles enabling a different agent for the same user is
how you end up with "communication with agent failed".

## What it does

| Area | How |
|------|-----|
| **Secret Service** (passwords) | Installs `gnome-keyring`; the daemon is socket-activated by the systemd user session and owns `org.freedesktop.secrets`. |
| **Login keyring unlock** | Handled by `pam_gnome_keyring` via the display manager (GDM ships this by default). Not configured here — see *Notes*. |
| **SSH agent** | Uses **OpenSSH's own** `ssh-agent.socket` (user unit) and exports `SSH_AUTH_SOCK` via `~/.config/environment.d`; `gcr-ssh-agent.socket` is disabled. gcr-ssh-agent busy-loops `ssh-add` at 100% CPU on passphrase-protected keys under a non-GNOME (niri) session — there is no passphrase prompter — which hangs SSH (e.g. Vorta/borg). Passphrases are entered per agent lifetime via `ssh-add`, not stored in the keyring. |
| **Polkit prompts** | Installs `polkit-gnome` and runs its authentication agent as a systemd user service bound to `graphical-session.target` — no changes to your niri `config.kdl`. |
| **Tooling** | Installs `libsecret` (`secret-tool`) and `seahorse` (GUI). |

## Requirements

- Arch Linux with `community.general` collection.
- A systemd-managed graphical session. `niri-session` (the default `niri.desktop`
  entry) activates `graphical-session.target`, which the polkit agent binds to.
- The play must run while the target user is logged in, because the `scope: user`
  systemd tasks talk to that user's session bus.

## Parameters

`meta/argument_specs.yml` is the contract, `defaults/main.yml` the values.

## Example Playbook

```yaml
- name: Configure the keyring and polkit agent
  ansible.builtin.import_role:
    name: gnome_keyring
```

## Notes

- **`SSH_AUTH_SOCK` takes effect on the next login**, because `environment.d` is
  read when the systemd user session starts. After the first run, log out/in (a
  fresh session is cleanest) and verify with `echo $SSH_AUTH_SOCK` →
  `…/ssh-agent.socket` and `ssh-add -l`.
- **Stale `SSH_AGENT_PID`** in the systemd user environment blocks
  `ssh-agent.service` via its `ConditionEnvironment=!SSH_AGENT_PID` guard (the
  socket then accepts connections but nothing answers → "communication with agent
  failed"). A common source is a fish universal variable
  (`set -e -U SSH_AGENT_PID`) or a shell profile that starts its own agent.
- **Why not gcr-ssh-agent for SSH:** on a non-GNOME session there is no
  passphrase prompter, so gcr tries to unlock passphrase-protected keys on demand
  via `ssh-add`, which then busy-loops at ~100% CPU and hangs the SSH connection.
  OpenSSH's plain agent has no such on-demand-unlock behaviour.
- **PAM / login keyring:** with GDM the login keyring is unlocked automatically.
  If you switch to a display manager / greeter without `pam_gnome_keyring` (e.g.
  greetd + tuigreet), you must add the `pam_gnome_keyring.so` `auth`/`session`
  lines to the relevant PAM stack — intentionally left out of this role.
