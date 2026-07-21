# Ansible Role: WireGuard

This role installs and configures WireGuard VPN on a Linux system.

## Requirements

*   Ansible 2.9 or higher
*   A Linux system with WireGuard support

## Role Variables

*   `wireguard_interface`: The name of the WireGuard interface (default: `wg0`).
*   `wireguard_address`: The IP address and subnet for the WireGuard interface.
*   `wireguard_port`: The UDP port WireGuard will listen on (default: `51820`).
*   `wireguard_peers`: A list of peers to configure.

## Dependencies

None.

## Example Playbook

```yaml
- hosts: servers
  roles:
    - role: wireguard
      wireguard_address: 10.0.0.1/24
      wireguard_peers:
        - public_key: <peer_public_key>
          allowed_ips: 10.0.0.2/32
```

## License

BSD-3-Clause

## Author

kreativmonkey