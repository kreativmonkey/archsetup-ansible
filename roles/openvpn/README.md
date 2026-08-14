# openvpn

Configures OpenVPN tunnels as **split tunnels in NetworkManager**: only the
declared networks are routed through the tunnel, and only the declared zones are
resolved by the internal resolvers. Everything else keeps using the normal
default route and the normal resolver.

Because the tunnel is a NetworkManager profile, it appears in the desktop network
menu and is started from there — and its passwords live in the **login keyring**,
not in a file. This role never sees or stores a secret.

Derived from the NixOS module `puzzle.vpn.puzzle`
(`puzzle-nixos-modules/modules/network/puzzle-vpn.nix`) and it keeps that
module's contract, including the deliberate one: the `.ovpn` profile with the key
material is **not** part of the configuration this role owns.

The role ships **no tunnel of its own**. A tunnel definition is host data: it
belongs in the inventory, and every value in it that identifies your
infrastructure should come from a lookup, not from a literal in a public
repository.

## What it does

| Area | How |
|------|-----|
| **Packages** | `openvpn` and `networkmanager-openvpn`. |
| **Profile source** | checked out through the `git` role's `checkout` entry point, only when the tunnel gives a `profile_repo`. |
| **Profile** | `nmcli connection import type openvpn`, once, then renamed to `connection_name`. |
| **Split policy** | `ipv4.never-default`, `ipv4.ignore-auto-routes`, `ipv4.ignore-auto-dns`, `ipv4.routes`, `ipv4.dns`, `ipv4.dns-search`, the same three switches for IPv6, and `connection.autoconnect=no`. |
| **Secrets** | `password-flags=1` and `cert-pass-flags=1` — agent owned, so gnome-keyring stores them. |
| **Resolver** | `systemd-resolved` and `NetworkManager` started and enabled. |
| **Checks** | `/etc/resolv.conf` handed to systemd-resolved. |

It does **not** activate a tunnel, and `autoconnect` stays off. Starting one is a
decision per session:

```console
nmcli connection up "Puzzle VPN BE3" --ask
```

or just click it in the network menu. The first start asks for the account
password and the certificate passphrase; tick *remember* and they go into the
login keyring, unlocked by your login from then on.

## The vault has to be unlocked

Like `roles/wireguard`, the tunnel definitions resolve their values through a
lookup, and argument spec validation forces that lookup **before the role's first
task**. A locked vault therefore fails the whole play. Either `bw unlock` first,
or skip the role:

```console
ansible-playbook -i localhost, --connection local --skip-tags openvpn setup_workstation.yml
```

## Parameters

`meta/argument_specs.yml` is the contract.

## Example: a corporate VPN with the profiles in a git repository

In the inventory, with every identifying value out of a password manager:

```yaml
openvpn_tunnels:
  - name: puzzle
    connection_name: Puzzle VPN BE3
    profile_repo:
      repo: "{{ lookup('community.general.bitwarden', 'Puzzle VPN', field='ProfileRepo') | first }}"
      dest: /etc/openvpn/puzzle
      version: main
      owner: root
      mode: "0700"
      key_file: /home/sebastian/.ssh/id_ed25519
    # relative to profile_repo.dest, e.g. BE3/puzzle_vpn_be3.ovpn
    profile_path: "{{ lookup('community.general.bitwarden', 'Puzzle VPN', field='ProfilePath') | first }}"
    split_tunnel:
      routes: "{{ lookup('community.general.bitwarden', 'Puzzle VPN', field='Routes') | first | split(',') | map('trim') | list }}"
      dns: "{{ lookup('community.general.bitwarden', 'Puzzle VPN', field='DNS') | first | split(',') | map('trim') | list }}"
      routing_domains: "{{ lookup('community.general.bitwarden', 'Puzzle VPN', field='RoutingDomains') | first | split(',') | map('trim') | list }}"
```

No credentials anywhere in that definition — that is the point of the
NetworkManager path.

## Verifying that the split actually splits

Both halves have to be checked: what is routed, and what is resolved. `nmcli`
showing the right properties only proves intent.

```console
# does a packet for an internal network take the tunnel?
ip route get 10.10.0.1          # expect: dev tun0
ip route get 1.1.1.1            # expect: still your uplink, NOT tun0

# does the zone resolve over the tunnel, and nothing else?
resolvectl query wiki.puzzle.ch # expect: -- link: tun0
resolvectl query archlinux.org  # expect: any link but tun0

# the two lines that prove split DNS
resolvectl status tun0          # DNS Domain: ~puzzle.ch / Default Route: no
```

A tunnel started outside NetworkManager shows up as `connected (externally)` in
`nmcli device status`; one this role configured is a real profile and appears in
the network menu.

## Notes

- **The `.nmconnection` file is not ours.** NetworkManager rewrites it whenever
  the profile changes, from the applet as much as from `nmcli`. Writing it with
  `template` would fight that, so the role owns *named properties* through
  `nmcli` instead — the same shared-ownership rule that makes other roles reach
  for `lineinfile`. Puzzle's own `NMconfig.sh` does write the file directly,
  which is fine for a one-shot script and wrong for something that runs again
  tomorrow.
- **The profile is imported, not composed.** The remote, the data cipher, the auth
  digest, the tls-auth direction and the paths of the four referenced files all
  come out of the `.ovpn`. Restating them here would mean maintaining a second
  copy that drifts from upstream. The trade-off: a *changed* upstream profile does
  not update an already imported connection — delete it and re-run.
- **`community.general.nmcli` cannot do the import.** Its `vpn` type models PPTP
  and L2TP only, with no `ca`, `cert`, `key` or `ta`, so a certificate based
  OpenVPN profile is out of reach. It is used for none of this; the properties are
  set with `nmcli` and compared before writing.
- **Drift is compared as normalised sets.** `nmcli` picks its own separators and
  ordering for list valued properties, so comparing raw strings would report a
  change on every run. Values are split on commas, trimmed and sorted on both
  sides.
- **`+vpn.data`, never `vpn.data`.** Secret flags live in the same dictionary as
  `ca`, `cert` and `key`. Assigning `vpn.data` would replace all of it and take
  the certificate paths with it.
- **Secret flag `1` is what puts the password in the keyring.** The default `0`
  means *the system stores this*, which is NetworkManager writing it in clear text
  into `/etc/NetworkManager/system-connections`. Puzzle's script sets
  `password-flags=1` but leaves the certificate passphrase at the default; this
  role sets `cert-pass-flags=1` as well.
- **A search domain routes too.** In systemd-resolved a search domain is also a
  routing domain; the `~` prefix means *route but do not append as a suffix*. So
  `puzzle.ch` in `routing_domains` gives you both, and `~puzzle.ch` gives routing
  only. Puzzle's own profile uses the bare form.
- **Routes are checked before they reach `nmcli`.** A hand maintained list picks
  up shorthands — a leading dot for *same network as the line above*, shell style
  braces for a range of octets — and `nmcli` answers those with a localised error
  on the one property write at the end of the run. The role rejects them up front
  and names the entries instead.
- **IPv4 only for routes, like the NixOS module.** IPv6 gets `never-default` and
  both `ignore-auto` switches so nothing leaks, but no IPv6 networks are routed
  in. Add `ipv6.routes` here if a tunnel ever needs it.
- **`profile_path` is relative to the checkout** unless it starts with a slash.
  `BE3/puzzle_vpn_be3.ovpn` names the site and nothing else; where this host puts
  the working copy is `profile_repo.dest`, an inventory decision that has no
  business being in a password manager item. A relative path without a
  `profile_repo.dest` to resolve against fails early and says so.
- **The checkout has to stay where it is.** NetworkManager stores absolute paths
  to the CA, certificate and keys at import time, so moving or deleting
  `profile_repo.dest` breaks an already imported profile.
- **No `update-systemd-resolved` any more.** The systemd path needed that AUR
  package to push resolvers over DBus. NetworkManager does it itself, so this role
  no longer touches the AUR at all.
