# Nix Development Shells

This directory contains modular Nix shell configurations for the dotfiles
project.

## Structure

```
Packages/shared/
├── default.nix    # Main entry point, orchestrates all shells
├── dots.nix       # Primary development shell
├── fmt.nix        # Code formatting and linting tools
└── media.nix      # Media processing tools
```

## Available Shells

### `dots` (default)

The main development shell with everything needed for dotfiles management.

**Access**: `nix develop` or `nix develop .#dots`

**Includes**:

- **CLI Applications**: Generated command wrappers (`.info`, `.rebuild`, etc.)
- **Formatters**: Code quality tools (alejandra, shfmt, rustfmt, etc.)
- **Media Tools**: Video/audio processing (mpv, ffmpeg, yt-dlp, etc.)
- **Rust Scripts**: Lightweight scripting with `rust-script`
- **Development Utilities**: File tools, search, Git UI, and more
- **Platform-Specific**: Clipboard tools for Linux/macOS

**Features**:

- Dynamic host detection
- Automatic cache directory setup (`$DOTS_CACHE`)
- Starship prompt integration
- Grouped command help on shell entry

### `media`

Standalone shell for media processing work.

**Access**: `nix develop .#media`

**Includes**:

| Tool          | Purpose                         |
| ------------- | ------------------------------- |
| `mpv`         | Media player                    |
| `ffmpeg-full` | Complete FFmpeg with all codecs |
| `yt-dlp`      | YouTube/video downloader        |
| `mediainfo`   | Media file analyzer             |
| `mkvtoolnix`  | Matroska container tools        |

## Architecture

### Package Composition

The shells use a modular composition pattern to avoid duplication:

```nix
# default.nix orchestrates everything
fmt = import ./fmt.nix {...};
media = import ./media.nix {...};
dots = import ./dots.nix {
  fmtPackages = fmt.formatters;
  mediaPackages = media.packages;
};
```

**Key principles**:

1. **Single source of truth**: Each package set is defined once
2. **Explicit passing**: Dependencies are passed as parameters
3. **Dual exports**: Modules export both `packages` (list) and `shell`
   (environment)

### Why This Pattern?

- **No duplication**: Formatters and media tools are defined once
- **Composable**: Easy to add new package sets
- **Clear dependencies**: Parameter passing makes relationships explicit
- **Reusable**: Each shell can be used standalone or combined

## Adding New Package Sets

> **Philosophy**: These shells are for **utility tools**, not full development
> environments. For language development (Rust, Python, Go, etc.), use the
> dedicated flake templates which provide proper LSP, formatters, and project
> structure. Devshells should contain tools you want available system-wide for
> quick tasks.

### Example: Document Processing Tools

1. Create a new file (e.g., `docs.nix`):

```nix
{pkgs}: let
  packages = with pkgs; [
    pandoc        # Universal document converter
    typst         # Modern LaTeX alternative
    imagemagick   # Image processing
    poppler_utils # PDF utilities (pdfunite, pdfseparate)
    qpdf          # PDF transformation
  ];

  shell = pkgs.mkShell {
    name = "doc-tools";
    inherit packages;
  };
in {
  inherit packages shell;
}
```

2. Import in `default.nix`:

```nix
docs = import ./docs.nix {inherit pkgs;};
dots = import ./dots.nix {
  # ...
  docsPackages = docs.packages;
};
```

3. Add to `dots.nix` parameters:

```nix
{
  # ...
  docsPackages ? [],
  ...
}: let
  packages = with pkgs;
    [...]
    ++ docsPackages;  # Document processing tools
```

### Other Good Examples

**Database Tools** (`db.nix`):

```nix
packages = with pkgs; [
  postgresql_16  # psql client
  sqlite         # SQLite CLI
  pgcli          # Better PostgreSQL CLI
];
```

**Web/API Tools** (`web.nix`):

```nix
packages = with pkgs; [
  httpie         # Better curl
  websocat       # WebSocket client
  bruno          # API client
];
```

## Package Organization in dots.nix

Packages are organized for clarity:

```nix
packages = with pkgs;
  [
    # Core utilities (alphabetically sorted)
    actionlint
    bat
    # ...
  ]
  ++ (attrValues applications)  # Generated CLI commands
  ++ fmtPackages                # Code formatters
  ++ mediaPackages              # Media processing tools
  ++ (optionals isLinux [...])  # Platform-specific
```

## Commands

The `dots` shell generates command wrappers from the main Rust CLI:

### System/Info

- `.info` - Show system information
- `.hosts` - List available hosts

### Build/Rebuild

- `.boot` - Build configuration for next boot
- `.dry` - Dry run rebuild
- `.rebuild` - Rebuild NixOS configuration
- `.check` - Run all checks
- `.fmt` - Format the project tree

### Maintenance/Utilities

- `.clean` - Clean old generations
- `.list` - List all available commands
- `.help` - Show help information

### Interaction/REPL

- `.repl` - Enter Nix REPL

### Discovery/Search

- `.search` - Search for patterns

### Version Control/Update

- `.update` - Update flake inputs
- `.sync` - Commit and push changes
- `.status` - Show repository status

## Environment Variables

The `dots` shell configures:

| Variable           | Description                                |
| ------------------ | ------------------------------------------ |
| `$HOSTNAME`        | Current system hostname                    |
| `$HOSTTYPE`        | System architecture (e.g., `x86_64-linux`) |
| `$DOTS_CACHE`      | Cache directory (default: `$DOTS/.cache`)  |
| `$ENV_BIN`         | Binary cache directory                     |
| `$DOTS_LOGS`       | Log directory                              |
| `$DOTS_TMP`        | Temporary files directory                  |
| `$STARSHIP_CONFIG` | Prompt configuration path                  |

## Development Workflow

1. **Enter the shell**:
   ```bash
   nix develop
   ```

2. **Use generated commands**:
   ```bash
   .rebuild  # Rebuild system
   .fmt      # Format code
   .check    # Run checks
   ```

3. **Access tools directly**:
   ```bash
   mpv video.mp4
   yt-dlp https://youtube.com/watch?v=...
   ffmpeg -i input.mp4 output.webm
   ```

4. **Format on save** (if using direnv):
   ```bash
   echo "use flake" > .envrc
   direnv allow
   ```

## Customization

### Adding Packages

Edit the utilities list in `dots.nix`:

```nix
packages = with pkgs;
  [
    # Your new package here
    neovim
    # ...
  ]
```

### Platform-Specific Packages

Use `optionals` for conditional inclusion:

```nix
++ (optionals isLinux [linux-only-tool])
++ (optionals isDarwin [macos-only-tool])
```

### Custom Commands

Add to the `aliases` list in `dots.nix`:

```nix
{
  name = "mycommand";
  description = "Does something useful";
}
```

Then implement in `Bin/rust/.dots.rs`.

## Troubleshooting

### Command not found after entering shell

- Ensure `$ENV_BIN` is in `$PATH`
- Check that the shell hook ran: `echo $DOTS_CACHE`
- Try restarting the shell: `exit` then `nix develop`

### Formatters not working

- Verify treefmt configuration exists: `ls treefmt.toml`
- Run manually: `treefmt --help`
- Check formatter PATH: `echo $PATH | grep -o '/nix/store/[^:]*treefmt[^:]*'`

### Missing packages

- Check if package exists: `nix search nixpkgs <package>`
- Verify spelling in package list
- Ensure flake lock is up to date: `.update`

## Contributing

When adding new functionality:

1. **Keep modules focused**: Each `.nix` file should have a single purpose
2. **Document parameters**: Use comments for non-obvious options
3. **Export consistently**: Always export both `packages` and `shell`
4. **Test standalone**: Each shell should work with `nix develop .#<name>`
5. **Update this README**: Document new shells or significant changes

## Further Reading

- [Nix Pills](https://nixos.org/guides/nix-pills/) - Deep dive into Nix
- [NixOS Manual](https://nixos.org/manual/nixos/stable/) - Official
  documentation
- [Zero to Nix](https://zero-to-nix.com/) - Modern Nix tutorial
- [Determinate Systems](https://determinate.systems/posts/) - Advanced patterns
