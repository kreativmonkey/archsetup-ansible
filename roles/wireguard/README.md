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
| **Keys** | `wg genkey` per interface into `/etc/wireguard/privatekey-<name>`, `0600`, generated once. |
| **Config** | `/etc/wireguard/<name>.conf`, `0600`, from `templates/interface.conf.j2`. |
| **Forwarding** | `net.ipv4.ip_forward` through the `sysctl` role, only with `wireguard_forward_ipv4`. |

It does **not** start or enable `wg-quick@<name>`. Bringing a tunnel up is a
decision per boot, not per config run — `systemctl enable --now wg-quick@wg0`.

## Parameters

`meta/argument_specs.yml` is the contract.

## Example: a client tunnel with split DNS

In the inventory, with every identifying value out of a password manager:

```yaml
wireguard_interfaces:
  - name: mylab
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

- **`DNS =` alone does not give you split DNS.** It tells `wg-quick` which
  resolver to use; it does not make systemd-resolved *route* a zone to it. That
  needs a routing domain, which is what the `~` prefix in
  `resolvectl domain %i ~example.org` does. `search_domains` generates that
  `PostUp`/`PostDown` pair and adds the `~` when you leave it off.
- **The templates used to be named after the tunnels.** There was a
  `pudelab.conf.j2` and a `wg0.conf.j2`, each with the addresses and the DNS
  server of one specific network written into it, in a public repository. There
  is one generic template now, and the values come from the inventory.
- **The old `main.yml` looped `include_tasks` with
  `loop_var: wireguard_interface`** while `wireguard_interface` was also a
  variable in `defaults/main.yml` — the loop shadowed the default, so the default
  was decoration. The loop variable is the interface *dict* now, and there is no
  default to shadow.
- **`wg genkey | tee | wg pubkey` needs `pipefail`.** Without it the shell
  reports the exit status of the last command in the pipe, so a failing `genkey`
  passes silently and leaves an empty private key behind.
- **The private key never reaches a log.** The slurp and the template task are
  `no_log: true`.
- **Keys are generated once.** `creates:` on the shell task means an existing key
  pair is never regenerated — regenerating would silently lock this host out of
  every peer that has the old public key.
