dotDOTS
=======

A collection of personal tools and configurations for portable and
efficient setups across systems.

Key Features
------------

-   **POSIX Compliance**: Scripts work on POSIX systems.
-   **Rust Migration**: Upgrading scripts to Rust for performance.
-   **Nix Flakes**: Configurations use Nix flakes (non-Windows).

Installation
------------

Clone the repo to desired location of the dots:

.. code-block:: sh

   DOTS="$HOME/.dots"
   git clone "https://github.com/craole-cc/dotfiles.git" "$DOTS"

Non-NixOS Systems
------------------

Dependencies: ``bash/sh`` ``coreutils``

1.  Set ``bash`` as the default shell:

    -   Unix-based: In the terminal execute the command:
        ``chsh -s /bin/bash``
    -   Windows: Install Git for Windows and open Git Bash.

2.  Ensure the following lines are in your user profile:
    ``$HOME/.profile``

    .. code-block:: sh

       #| Initialize DOTS
       # shellcheck disable=SC1091
       DOTS="$HOME/.dots"
       export DOTS
       [ -f "$DOTS/.dotsrc" ] && . "$DOTS/.dotsrc"

3.  Ensure the following lines are in your bash profile:
    ``$HOME/.bashrc``

    .. code-block:: sh

       #| Initialize Profile
       # shellcheck disable=SC1091
       [ -f "$HOME/.profile" ] && . "$HOME/.profile"

4.  Logout and log back in or reboot the system.

NixOS Systems
--------------

Dependencies: ``nixos-rebuild`` ``sudo``

1.  In the ``flake.nix``, update the DOTS path ``paths.flake.local``

2.  Initialize your host config:

    .. code-block:: sh

       init_host_config(){
         host_conf="$DOTS/Configuration/apps/nixos/configurations/hosts/$(hostname)"
         host_conf_example="$(dirname "$host_conf")/example"
         [ -d "$host_conf_example" ] || {
           printf "Failed to locate the example config: %s" "$host_conf_example"
           return 1
         }
         sudo mkdir -p "$host_conf"
         sudo cp -u "$host_conf_example"/* "$host_conf"
         sudo cp -u /etc/nixos/* "$host_conf"
         ls -lAhRF "$host_conf" | grep -v '^total'
       } && init_host_config

    Update ``default.nix`` with data from
    ``hardware-configuration.nix`` and ``configuration.nix``.

Structure and Key Files
-----------------------

-   ``Bin/``: The scripts folder.
-   ``.dotsrc``: Initialization script.
-   ``flake.nix``: Configuration file for Nix.
-   ``LICENSE``: Licensing information.

Contributing
------------

Pull requests are welcome.

License
-------

This project is licensed under the MIT License.
