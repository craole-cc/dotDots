# 🎯 dotDots: NixOS Configuration Management CLI

**dotDots** is a comprehensive CLI tool and development environment for managing the dotDots NixOS Configuration Flake with a focus on productivity, discoverability, and workflow automation. Built as a Rust-powered CLI with Nix integration, it provides quick access to common system management tasks with intelligent defaults and clipboard integration.

## ✨ Features

- **🚀 Quick Command Access**: Short underscore-prefixed commands (`_rebuild`, `_info`, etc.)
- **📋 Smart Clipboard**: Commands automatically copy to clipboard for quick execution
- **🔍 Host Discovery**: Automatically detects and works with the current host
- **📊 System Insights**: Integrated with tools like `onefetch` and `tokei` for repository stats
- **🛠️ Development Environment**: Complete Nix development shell with formatters and tools
- **🎨 Colorful Output**: Colored terminal output for better readability
- **🔄 Workflow Commands**: Specialized commands for common development workflows

## 🚀 Quick Start

### Entering the Development Environment

```bash
# From your NixOS configuration directory
nix develop

# Or if using direnv
direnv allow
```

You'll be greeted with a welcome message showing your current host and available commands.

### Basic Usage

```bash
# List all configured hosts
_hosts

# Show information about current host
_info

# Show rebuild command for current host (copied to clipboard)
_rebuild

# Execute rebuild immediately
_rebuild --execute

# Show rebuild command for specific host
_rebuild QBX

# Test configuration without applying
_test --execute
```

## 📋 Command Reference

### Core Commands

| Command | Description | Example |
|---------|-------------|---------|
| `hosts` / `_hosts` | List all configured hosts | `_hosts` |
| `info` / `_info` | Show detailed host information | `_info QBX` |
| `rebuild` / `_rebuild` | Rebuild and switch to new configuration | `_rebuild --execute` |
| `test` / `_test` | Test configuration without making it permanent | `_test --execute` |
| `boot` / `_boot` | Build and add to boot menu | `_boot --execute` |
| `dry` / `_dry` | Dry build without making changes | `_dry` |
| `update` / `_update` | Update flake inputs | `_update --execute` |
| `clean` / `_clean` | Run garbage collection | `_clean --execute` |
| `list` / `_list` | List all available commands | `_list` |
| `help` / `_help` | Show help message | `_help` |

### Workflow Commands

These are shorthand commands for common development workflows (defined in `default.nix`):

| Command | Likely Purpose |
|---------|----------------|
| `_flick` | Quick switch/rebuild |
| `_flush` | Clear caches or logs |
| `_fmt` | Format code |
| `_fo` | File operations |
| `_ff` | Fast find/search |
| `_flow` | Workflow automation |
| `_flare` | Debug/status check |
| `_ft` | File tree/view |

*Note: These are wrapper scripts that can be customized in `default.nix`.*

## 🔧 Installation & Setup

### As a Nix Flake Development Shell

Add to your `flake.nix`:

```nix
{
  inputs = {
    # Your inputs...
  };

  outputs = { self, nixpkgs, ... }: {
    devShells = {
      default = import ./Packages/custom/dots {
        inherit pkgs;
        # Add other required arguments from your flake
      };
    };
  };
}
```

### Environment Variables

The shell sets up several useful environment variables:

- `DOTS`: Path to dots directory
- `DOTS_BIN`: Path to dots binaries
- `BINIT`: Base initialization script
- `ENV_BIN`: Directory for wrapper scripts
- `HOST_NAME`: Current host name
- `HOST_TYPE`: Host platform/type

## 🛠️ Development Tools Included

The development environment comes with a comprehensive set of tools:

### Code Formatters & Linters
- **alejandra**: Nix code formatter
- **nixfmt**: Alternative Nix formatter
- **taplo**: TOML formatter and linter
- **shfmt**: Shell script formatter
- **shellcheck**: Shell script linter
- **treefmt**: Unified formatting tool
- **rustfmt**: Rust code formatter
- **yamlfmt**: YAML formatter

### Development & Git Tools
- **rust-analyzer**: Rust language server
- **nil** & **nixd**: Nix language servers
- **gitui**: Terminal UI for git
- **onefetch**: Repository info display
- **tokei**: Code statistics

### Utilities
- **bat**: Syntax-highlighting cat replacement
- **fd**: Fast file finder
- **yazi**: TUI file manager
- **undollar**: Shell variable replacement

## 📁 Project Structure

```
Packages/custom/dots/
├── Cargo.toml          # Rust package configuration
├── default.nix         # Nix shell definition
├── main.rs            # Rust CLI implementation
└── repl.nix           # Nix REPL with helper functions
```

### Key Components

1. **Rust CLI (`main.rs`)**: The main implementation with colored output, clipboard integration, and command parsing
2. **Nix Shell (`default.nix`)**: Development environment with all tools and wrapper scripts
3. **Nix REPL (`repl.nix`)**: Interactive REPL with host information and helper functions

## 🔍 Host Information Display

The `info` command shows comprehensive host details:

```bash
_info
```

Displays:
- Hostname and system architecture
- Kernel version and state version
- Desktop environment
- Repository information (via onefetch)
- Code statistics (via tokei)

## 📋 Clipboard Integration

All commands that generate shell commands automatically copy them to your clipboard:

```bash
# Command is displayed AND copied to clipboard
_rebuild

# You can immediately paste with Ctrl+V or Ctrl+Shift+V
```

Supported on both X11 and Wayland via `arboard` with fallbacks to `xclip`, `wl-clipboard`, and `xsel`.

## 🔄 REPL Access

The project includes a Nix REPL with helper functions:

```bash
nix repl ./repl.nix
```

Available in REPL:
- `helpers.scripts`: Command generators
- `helpers.listHosts`: List all hosts
- `helpers.hostInfo`: Get detailed host info
- `helpers.compareHosts`: Compare two hosts
- Direct access to host configuration

## 🎨 Customization

### Adding New Commands

Edit `default.nix` to add new wrapper commands:

```nix
commands = listToAttrs (
  map
  (cmd: { name = "_${cmd}"; value = mkCmd cmd; })
  [
    # Add new commands here
    "mycommand"
    # ...
  ]
);
```

### Customizing the Environment

The development environment can be extended by modifying the `packages` list in `default.nix`:

```nix
packages = with pkgs; [
  # Add additional tools
  my-custom-tool
  # ...
];
```

## 🤝 Contributing

### Building the Rust CLI

```bash
# Build for development
cargo build

# Build for release
cargo build --release

# Run directly
cargo run -- hosts
```

### Code Style

- Rust code formatted with `rustfmt`
- Nix code formatted with `alejandra` or `nixfmt`
- Use `treefmt` to format all files at once

## 🐛 Troubleshooting

### Clipboard Not Working

Ensure you have appropriate clipboard utilities installed:
- X11: `xclip` or `xsel`
- Wayland: `wl-clipboard`

### Host Detection Issues

Check environment variables:
```bash
echo $HOST_NAME
echo $HOST_PLATFORM
```

### Command Not Found

Ensure you're in the development shell:
```bash
nix develop
```

## 📄 License

This project is part of a larger NixOS configuration. The Rust CLI is built with common Rust dependencies under their respective licenses.

## 🔗 Related Components

- **NixOS Configuration**: Managed by the CLI
- **Flake Structure**: Defined in the parent flake
- **Host Definitions**: In `api.hosts`
- **User Configuration**: In `api.users`

---

Built with ❤️ for NixOS enthusiasts. Use `_help` for quick reference anytime!
