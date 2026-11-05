# kdeconnect

Installs KDE Connect for the niri session and opens its ports (1714-1764
tcp/udp, the predefined firewalld service `kdeconnect`) in the trusted zones.
The firewall change goes through the `firewalld` role's `add_service` entry
point.

The daemon `kdeconnectd` starts from the package's XDG autostart entry. Pair the
phone from the KDE Connect app on the phone, or with `kdeconnect-cli
--list-available` and `kdeconnect-cli --pair -d <id>`.

## Example

```yaml
- name: Set up KDE Connect
  ansible.builtin.import_role:
    name: kdeconnect
  vars:
    kdeconnect_firewall_zones:
      - home
```

## Notes

- **Only trusted zones.** On this laptop the Wi-Fi sits in `home` and the dock
  Ethernet in `block`. Opening the service in `block` or `public` exposes the
  pairing ports on foreign networks.
