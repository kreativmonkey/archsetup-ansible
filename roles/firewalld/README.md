# firewalld

Installs firewalld with the nftables backend and keeps its **IPv6 reverse path
filter** compatible with the policy routing rules a WireGuard-style VPN client
(NetBird, Tailscale) installs.

That single setting is the whole point of this role. It is not a general
firewall role: it manages no zones, no services, no ports.

## What it does

| Area | How |
|------|-----|
| **Packages** | `firewalld`, `nftables` (`nft` is needed for the verification below). |
| **Service** | `firewalld` enabled and started. |
| **Config** | `IPv6_rpfilter` in `/etc/firewalld/firewalld.conf` via `lineinfile`, then `firewall-cmd --reload`. |
| **Verification** | Reads `filter_PREROUTING` from nftables and asserts the reverse path drop rule is gone. |

The config file stays `root:root 0600`. No backup copy is written — a stray
`firewalld.conf.<timestamp>~` in `/etc/firewalld/` is clutter in a directory
firewalld itself reads, and the desired state lives in this role anyway.

## Role Variables

See `defaults/main.yml`:

- `firewalld_ipv6_rpfilter` — the value written to `firewalld.conf`. Default
  `"no"`. Allowed per `firewalld.conf(5)`: `strict`, `loose`,
  `strict-forward`, `loose-forward`, `no`. Quote it; bare `yes`/`no` are YAML
  booleans and get mapped back to `strict`/`no`.
- `firewalld_conf` — path of the managed file.
- `firewalld_verify` — run the structural nftables check (default `true`).
- `firewalld_verify_ping_target` — destination of the optional connectivity
  probe, default `2001:4860:4860::8888`.

## Why `IPv6_rpfilter=no`

### The symptom

IPv4 works. IPv6 is configured and looks healthy — global address via SLAAC,
default route via RA, gateway reachable with `ping6` on its link-local address
— and yet **no global IPv6 destination answers**. TCP connections sit in
`SYN-SENT`, `Icmp6InEchoReplies` in `/proc/net/snmp6` stays at 0.

Everything with its own HTTP stack is affected: `nix`, Evolution,
Vorta/Borg, statusbar tools. `curl` still works, because Happy Eyeballs falls
back to IPv4 after ~200 ms — which is exactly what makes this bug so tedious.
The obvious check with `curl` falsely confirms that IPv6 is fine.

### The cause

The VPN client installs IPv6 policy routing rules:

```
105:   from all lookup main suppress_prefixlength 0
110:   not from all fwmark 0x1bd00 lookup 7120     # table 7120 is empty
32766: from all lookup main
```

`suppress_prefixlength 0` hides the default route from the lookup. With
`IPv6_rpfilter=strict`, firewalld generates in `table inet firewalld`:

```
chain filter_PREROUTING {
    type filter hook prerouting priority filter + 10; policy accept;
    icmpv6 type { nd-router-advert, nd-neighbor-solicit } accept
    meta nfproto ipv6 fib saddr . mark . iif check missing drop
}
```

For a global source address the reverse path lookup no longer matches, so the
packet is dropped. The two exceptions let RAs and neighbor solicitations
through, which is why address configuration and NDP appear intact while every
payload reply disappears. Link-local keeps working because `fe80::/64` is a
real route with prefix length 64.

`IPv6_rpfilter=no` removes that rule. On this system the VPN client filters
IPv4 only (`table ip netbird`), so dropping the IPv6 reverse path check adds no
risk to the mesh connection.

`strict-forward` is the narrower profile — it keeps reverse path filtering for
forwarded traffic and exempts traffic addressed to the host — and it also fixes
the symptom. Set `firewalld_ipv6_rpfilter: strict-forward` if you want it, and
then verify by hand (see below).

## Verification

Structural, runs as part of the role:

```console
nft list chain inet firewalld filter_PREROUTING
```

must no longer contain `fib saddr . mark . iif check missing drop`. With
`firewalld_ipv6_rpfilter: "no"` the role asserts exactly this. A chain that
does not exist counts as clean; a query that could not run at all (no `nft`, no
root) fails instead of passing silently. For any other mode a fib check
legitimately remains, so the role only prints the chain instead of asserting —
see the dead ends below.

Functional, optional and never an assertion:

```console
ansible-playbook setup.yml --tags firewalld_connectivity
```

runs `ping -6 -c 2 2001:4860:4860::8888` and reports the result. It is tagged
`never` on purpose: on a fresh install IPv6 can be dead for entirely different
reasons, and the role must not fail because of them.

## Dead ends — do not repeat these

- **Setting the interface zone to `trusted` does not help.** The drop rule sits
  in `filter_PREROUTING`, i.e. before zone evaluation. The zone (`block` was
  the default for the LAN interface here) is irrelevant.
- **`loose` is not a reliable fix.** Suppressing the default route affects the
  route lookup itself, independently of the `iif` component. Anyone who wants
  `loose` has to measure it, not assume it.
- **Do not touch the IPv4 `rp_filter`.** That runs through sysctl and is not
  affected by this problem.
- **No DNS changes.** DNS returns correct AAAA records; that was never the
  problem.
- **Do not disable firewalld.**

## Not part of this role

The original trigger also had a firewall-side component: on the upstream router
the DHCPv6/RA interface had the *Upstream Gateway* (`defaultgw`) flag unset, so
no `::/0` route existed while RAs kept advertising a default router. That is
fixed and belongs in the network/OPNsense automation, not in a workstation
role.

## Example Playbook

```yaml
- hosts: localhost
  become: true
  roles:
    - firewalld
```

Narrower profile, chosen from the inventory:

```yaml
firewalld_ipv6_rpfilter: strict-forward
```
