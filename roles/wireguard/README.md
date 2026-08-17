# wireguard

Generates a key pair per tunnel and writes one `wg-quick` config file per entry
in `wireguard_interfaces`. Client tunnels and server tunnels come out of the
same template.

The role ships **no interface of its own**. An interface definition is host
data: it belongs in the inventory, and every value in it that identifies your
infrastructure should come from a lookup, not from a literal in a public
repository.

## What it does

| Area | How |
|------|-----|
| **Packages** | `wireguard-tools`. |
| **Keys** | `wg genkey` per interface into `/etc/wireguard/privatekey-<name>`, `0600`, generated once — or the `private_key` from the interface definition, when the peer already knows the matching public key. |
| **Config** | `/etc/wireguard/<name>.conf`, `0600`, from `templates/interface.conf.j2`. |
| **Forwarding** | `net.ipv4.ip_forward` through the `sysctl` role, only with `wireguard_forward_ipv4`. |

It does **not** start or enable `wg-quick@<name>`. Bringing a tunnel up is a
decision per boot, not per config run — `systemctl enable --now wg-quick@wg0`.

## The vault has to be unlocked

The interface definitions resolve their values through a lookup, and argument
spec validation forces that lookup **before the role's first task**. With the
role in `setup_workstation.yml`, a locked vault therefore fails the whole play:

```
The lookup plugin 'community.general.bitwarden' failed:
Bitwarden Vault locked. Run 'bw unlock'.
```

Either `bw unlock` first, or skip the role:

```console
ansible-playbook -i localhost, --connection local --skip-tags wireguard setup_workstation.yml
```

`--skip-tags` is enough — a skipped task never evaluates its arguments, so the
lookup does not run.

## Parameters

`meta/argument_specs.yml` is the contract.

## Example: a client tunnel with split DNS

In the inventory, with every identifying value out of a password manager:

```yaml
wireguard_interfaces:
  - name: mylab
    # Only when the peer already knows this host's public key. Leave it out and
    # the role generates a pair, whose public key you then hand to the peer.
    private_key: "{{ lookup('community.general.bitwarden', 'WireGuard mylab', field='PrivateKey') | first }}"
    address: "{{ lookup('community.general.bitwarden', 'WireGuard mylab', field='Address') | first }}"
    dns: "{{ lookup('community.general.bitwarden', 'WireGuard mylab', field='DNS') | first }}"
    search_domains:
      - "{{ lookup('community.general.bitwarden', 'WireGuard mylab', field='SearchDomain') | first }}"
    mtu: 1300
    peers:
      - public_key: "{{ lookup('community.general.bitwarden', 'WireGuard mylab', field='PublicKey') | first }}"
        preshared_key: "{{ lookup('community.general.bitwarden', 'WireGuard mylab', field='PresharedKey') | first }}"
        allowed_ips: "{{ lookup('community.general.bitwarden', 'WireGuard mylab', field='AllowedIPs') | first }}"
        endpoint: "{{ lookup('community.general.bitwarden', 'WireGuard mylab', field='Endpoint') | first }}"
        persistent_keepalive: 25
```

## Example: a server tunnel

```yaml
wireguard_forward_ipv4: true
wireguard_interfaces:
  - name: wg0
    address: 10.0.0.1/24
    listen_port: 51820
    post_up:
      - "iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE"
    post_down:
      - "iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE"
    peers:
      - public_key: <peer public key>
        allowed_ips: 10.0.0.2/32
```

## Notes

- **`DNS =` is worse than useless for a split tunnel.** It tells `wg-quick`
  which resolver to use, but it does not make systemd-resolved *route* a zone to
  it — and on the way there `wg-quick` calls `resolvconf -x`, which the
  systemd-resolved shim reads as the routing domain `~.`: every DNS query of the
  whole system into the tunnel. With `search_domains` set, the config therefore
  carries no `DNS =` at all. Resolver and routing domain are set together, in
  one `PostUp`, through `resolvectl` — so the split is never briefly not a
  split. Without `search_domains`, `DNS =` stays and means what it says.
- **A routing domain is a `~` prefix.** `resolvectl domain %i ~example.org` is
  what makes systemd-resolved send that zone, and only that zone, to the
  tunnel's resolver. `search_domains` adds the `~` when you leave it off.
- **The templates used to be named after the tunnels.** There was a
  `pudelab.conf.j2` and a `wg0.conf.j2`, each with the addresses and the DNS
  server of one specific network written into it, in a public repository. There
  is one generic template now, and the values come from the inventory.
- **The old `main.yml` looped `include_tasks` with
  `loop_var: wireguard_interface`** while `wireguard_interface` was also a
  variable in `defaults/main.yml` — the loop shadowed the default, so the default
  was decoration. The loop variable is the interface *dict* now, and there is no
  default to shadow.
- **A routing domain must not start with a dot.** `resolvectl domain %i
  ~.example.org` is rejected as `Domain not valid`, the `PostUp` fails, and
  `wg-quick` then tears the tunnel down again — a tunnel that dies on a DNS
  detail. `search_domains` therefore strips leading `~`/`.` and trailing dots
  before it puts the `~` back on, so `.example.org`, `example.org` and
  `~example.org` all mean the same thing.
- **The public key is derived, never stored once.** It is what you hand to the
  peer, so it is recomputed from the private key on every run. Writing it beside
  a key that was later replaced left the two out of sync, and the tunnel then
  fails the only way WireGuard knows: silently, with no handshake.
- **The private key never reaches a log.** The generated one goes straight to
  disk; a supplied one, the slurp and the template task are `no_log: true`.
- **Keys are generated once.** `creates:` on the shell task means an existing key
  pair is never regenerated — regenerating would silently lock this host out of
  every peer that has the old public key.
- **A supplied `private_key` wins.** A peer that was set up elsewhere already
  knows one public key; only the matching private key completes a handshake, so
  the generation step is skipped entirely for such an interface.
