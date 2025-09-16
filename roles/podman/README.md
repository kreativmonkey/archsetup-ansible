podman
=========

Install and setup podman on Archlinux.

Requirements
------------

- ansible.posix.sysctl

Role Variables
--------------

- podman_replace_docker:  <bool> (Default: false) Uninstall docker and replace the docker command by podman
- podman_rootless:        <bool> (Default: true) Setup podman [rootless mode](https://wiki.archlinux.org/title/Podman#Rootless_Podman)
- podman_rootless_users:  <list> (required if podman_rootless = true) List of Systemusers who can access podman without root.


Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: username.rolename, x: 42 }

License
-------

BSD

Author Information
------------------

kreativmonkey <kerativmonkey@calyrium.org>