# dotDots

A collection of tools and configurations for for use across systems.

- **Windows**: Git Bash with `.dotsrc` for configuration. NixWSL is supported.

- **Linux**: NixOS with flakes. Non-NixOS can use Nix, Home Manager, or `.dotsrc`.

- **macOS**: Nix-darwin and Home Manager. (_Pending_)

  The goal is enhanced efficiency, portability, and simplicity across devices. Feel free to explore and adapt these configurations.

## Features

- **System-agnostic Utilities**: POSIX scripts and Rust binaries in [Bin](./Bin).
- **Nix Flakes**: Additional tooling and configuration made available.

## Installation

Clone the repo to desired location of the dots:

```sh
DOTS="$HOME/.dots"
git clone "https://github.com/craole-cc/dotDots.git" "$DOTS"
cd "$DOTS"
```

### Non-NixOS Systems

> Dependencies |> `bash/sh` `coreutils`

1. Set `bash` as the default shell:

   - Unix-based
     - In the terminal execute the command: `chsh -s /bin/bash`
   - Windows
     - Install Git for Windows if you haven't done so already.
     - Open Git Bash.
     - Git Bash uses bash by default, no extra steps needed.
       > For an enhanced developer experience on Windows, consider using [Windows Terminal](https://apps.microsoft.com/detail/9n8g5rfz9xk3?ocid=webpdpshare).

1. Ensure the following lines are in your user profile: `$HOME/.profile`

   ```sh
   #| Initialize DOTS
   # shellcheck disable=SC1091
   DOTS="$HOME/.dots"
   export DOTS
   [ -f "$DOTS/.dotsrc" ] && . "$DOTS/.dotsrc"
   ```

1. Ensure the following lines are in your bash profile: `$HOME/.bashrc`

   ```sh
   #| Initialize Profile
   # shellcheck disable=SC1091
   [ -f "$HOME/.profile" ] && . "$HOME/.profile"
   ```

1. Logout and log back in or reboot te system to complete the initialization.

### NixOS Systems

[![built with nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a)](https://builtwithnix.org)

> Dependencies: `nixos-rebuild` `sudo`

- In the flake.nix, update the DOTS path `paths.flake.local`

- Initialize your host config.

  - The script below matches the previous steps.

    ```sh
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
    ```

- Update `default.nix` with relevant data from the system-generated `hardware-configuration.nix` and loosely from `configuration.nix`.

## Structure and Key Files

- `.dotsrc`: Initialization script for managing environment variables and paths.
- `Bin/`: The scripts folder, organized into subfolders for categorization. The `.dotsrc` file adds these scripts to `PATH` for easy access.
- `flake.nix`: Configuration file for Nix-based environments.
- `LICENSE`: Details the licensing information.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to modify or improve.

### Guidelines

- Ensure compatibility across Windows, Linux, and macOS.
- Update or add relevant tests to validate changes.
- Maintain adherence to the overarching goals of efficiency, portability, performance, and simplicity.

## License

This project is licensed under the [Apache License](./LICENSE).
