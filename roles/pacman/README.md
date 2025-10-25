pacman
=========

Setting up pacman to better defaults.


Role Variables
--------------

pacman.parallel_downloads: <int> Default: 10 - Setup the number of parallel downloads to speedup updates
pacman.repos: <list> Default: show defaults/main.yml - Enable repositorys

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