# dotDOTS

dotDOTS is a collection of my personal tools and configuration files designed to be portable and efficient across various systems and environments. These configurations reflect my approach to creating a streamlined and consistent setup for:

- **Windows**: Primarily using Git Bash with support through `.dotsrc` to manage configurations. While I rarely use WSL but when I do, I use NixWSL, these are supported when needed.
- **Linux**: Focused on NixOS with flakes integration. Systems without nixos can use stanalone nix and home-manager or even less, just the dotsrc like on windows
- **macOS**: Additional configuration through nix-darwin and home-manager.

The goal of these configurations is to enhance efficiency, maintain portability, and prioritize simplicity while ensuring compatibility across devices ranging from desktops and laptops to servers and Raspberry Pi systems.

Others are welcome to explore and adapt these configurations as they see fit.

## Key Features

- **POSIX Compliance**: Scripts are designed to work on POSIX-compliant systems.
- **Rust Migration**: Legacy scripts are being upgraded to Rust for enhanced performance and maintainability.
- **Nix Flakes Integration**: Configurations leverage Nix flakes for non-Windows environments.
- **Cross-System Compatibility**: Scripts are stored in a separate `bin` folder to ensure availability and functionality across all systems, including Windows.

## Installation

Clone the repo to desired location of the dots:

```sh
DOTS="$HOME/.dots"
git clone "https://github.com/craole-cc/dotfiles.git" "$DOTS"
```

### Non-NixOS Systems

> Dependencies |> `bash/sh` `coreutils`

1. Set `bash` as the default shell:
   - Unix-based
     - In the terminal execute the command: `chsh -s /bin/bash`
   - Windows
     - Install Git for Windows if you haven't done so already.
     - Open Git Bash.
     - To set bash as the default shell for Git Bash, you don't need to perform any additional steps as it automatically uses bash when you open it. Consider using _[Window Terminal](https://apps.microsoft.com/detail/9n8g5rfz9xk3?ocid=webpdpshare)_ for a more superior developer experience including dropdown (quake) functionality.
2. Ensure the following lines are in your user profile: `$HOME/.profile`

   ```sh
   #| Initialize DOTS
   # shellcheck disable=SC1091
   [ -f "$DOTS/.dotsrc" ] && . "$DOTS/.dotsrc"
   DOTS="${DOTS:-"path/to/the/cloned/repo"}"
   export DOTS
   ```

3. Ensure the following lines are in your bash profile: `$HOME/.bashrc`

   ```sh
   #| Initialize Profile
   # shellcheck disable=SC1091
   [ -f "$HOME/.profile" ] && . "$HOME/.profile"
   ```

4. Logout and log back in or reboot te system to complete the initialization.

## NixOS Systems

> Dependencies: `nixos-rebuild` `sudo`

1. Initialize your host config.

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

- `Bin/`: The scripts folder, organized into subfolders for categorization. The `.dotsrc` file adds these scripts to `PATH` for easy access.
- `.dotsrc`: Initialization script for managing environment variables and paths on non-Linux and non-NixOS systems.
- `flake.nix`: Configuration file for Nix-based environments.
- `LICENSE`: Details the licensing information.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to modify or improve.

### Guidelines

- Ensure compatibility across Windows, Linux, and macOS.
- Update or add relevant tests to validate changes.
- Maintain adherence to the overarching goals of efficiency, portability, performance, and simplicity.

## License

This project is licensed under the [MIT License](./LICENSE).
