# nixos-lib-dir

A fast, cached utility for finding the most recent NixOS lib directory in the Nix store.

## Features

- ⚡ **Fast**: Uses `fd` when available (4-5x faster than find)
- 💾 **Cached**: Results cached for 10 minutes (configurable)
- 📋 **Clipboard**: Automatically copies result to clipboard
- 🔄 **Fallback**: Works with standard GNU `find` if `fd` unavailable
- 📊 **Benchmarking**: Built-in performance comparison tool
- 🎯 **Flexible**: Customizable search patterns and cache settings
- 🔍 **Source-safe**: Works when sourced or executed
- 🔇 **Quiet mode**: Silent operation for scripting

## Requirements

### Required
- GNU coreutils (find, stat, date)
- Writable `/tmp` directory
- NixOS or Nix package manager

### Optional
- `fd` - For faster searches (highly recommended)
- `hyperfine` - For detailed benchmarking statistics
- `wl-clipboard` (Wayland) - For automatic clipboard copy
- `xclip` or `xsel` (X11) - For automatic clipboard copy

## Installation

```bash
# Copy to your scripts directory
cp nixos-lib-dir ~/scripts/

# Make executable
chmod +x ~/scripts/nixos-lib-dir

# Add to PATH (in ~/.bashrc or ~/.zshrc)
export PATH="$HOME/scripts:$PATH"

# Install optional tools for better performance
nix-env -iA nixpkgs.fd
nix-env -iA nixpkgs.hyperfine

# Install clipboard utilities
# For Wayland
nix-env -iA nixpkgs.wl-clipboard

# For X11
nix-env -iA nixpkgs.xclip
# OR
nix-env -iA nixpkgs.xsel
```

## Usage

### Basic Usage

```bash
# Find most recent nixos lib directory (silent by default)
nixos-lib-dir
# Output: /nix/store/...-nixos/nixos/lib

# Verbose mode shows cache info and progress
nixos-lib-dir --verbose
# Found in cache: '/tmp/nixos-lib-dir' (3 min old)
# 📋 Copied to clipboard
# /nix/store/...-nixos/nixos/lib

# Quiet mode suppresses all output (useful for scripting)
nixos-lib-dir --quiet
# (no output, only sets clipboard and cache)

# Source it to use in scripts
. nixos-lib-dir
lib_path=$(cat /tmp/nixos-lib-dir)

# Or capture output
lib_path=$(nixos-lib-dir)
```

### Options

```bash
# Custom cache location
nixos-lib-dir --cache /tmp/my-cache

# Set cache age (in minutes)
nixos-lib-dir --age 5

# Custom search pattern
nixos-lib-dir --pattern '*-nixos-unstable/nixos/lib'

# Force cache refresh
nixos-lib-dir --refresh-cache

# Compare fd vs find performance
nixos-lib-dir --benchmark

# Verbose output
nixos-lib-dir --verbose

# Quiet mode (no output)
nixos-lib-dir --quiet

# Show help
nixos-lib-dir --help
```

### Advanced Examples

```bash
# Use in a script to import NixOS lib functions
LIB_DIR=$(nixos-lib-dir)
. "$LIB_DIR/make-disk-image.nix"

# Search for different pattern with short cache
nixos-lib-dir -p '*-nixos-23.11/nixos/lib' -a 1

# Combine options (verbose + custom cache)
nixos-lib-dir -c /tmp/custom -a 30 -d

# Silent operation for cron jobs
nixos-lib-dir -q  # Only updates cache and clipboard

# Force refresh with verbose output
nixos-lib-dir -f -d
```

## Caching Behavior

The script caches results to avoid repeated slow filesystem searches:

- **Default cache**: `/tmp/nixos-lib-dir`
- **Default age**: 10 minutes
- **Cache invalidation**: Automatic after max age expires
- **Force refresh**: Use `-f` or `--refresh-cache`
- **Pattern change**: Automatically refreshes cache

With verbose mode, cache age is shown:
```bash
$ nixos-lib-dir --verbose
Found in cache: '/tmp/nixos-lib-dir' (3 min old)
📋 Copied to clipboard
/nix/store/...-nixos/nixos/lib
```

## Performance

### Without fd (find only)
```bash
$ nixos-lib-dir --verbose
Searching with find (consider installing 'fd' for faster results)...
# Takes 3-4 seconds on typical Nix store
```

### With fd installed
```bash
$ nixos-lib-dir --verbose
Searching with fd...
# Takes 600-800ms on typical Nix store
# ~5x faster than find
```

### Benchmarking

```bash
# Simple benchmark
nixos-lib-dir --benchmark

# Output:
# ┌─────────────────────────────────┐
# │ Tool            │       Time ms │
# ├─────────────────────────────────┤
# │ find            │       3308 ms │
# │ fd              │        657 ms │
# └─────────────────────────────────┘
# ✓ fd is 403% faster than find (5x speedup)

# Detailed benchmark with hyperfine
nix-shell -p hyperfine --run 'nixos-lib-dir --benchmark'

# Output includes:
# - Mean time ± standard deviation
# - Min/max times
# - Statistical analysis
# - Markdown export to /tmp/benchmark-results.md
```

## Output Modes

### Default (Silent)
```bash
$ nixos-lib-dir
/nix/store/...-nixos/nixos/lib
```

### Verbose (`-d, --verbose`)
```bash
$ nixos-lib-dir --verbose
Found in cache: '/tmp/nixos-lib-dir' (3 min old)
📋 Copied to clipboard
/nix/store/...-nixos/nixos/lib
```

### Quiet (`-q, --quiet`)
```bash
$ nixos-lib-dir --quiet
# (no output - only updates cache and clipboard)
# Useful for background tasks or when you only need clipboard
```

## Exit Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 0 | `EXIT_SUCCESS` | Operation completed successfully |
| 1 | `EXIT_NO_MATCH` | No matching directories found |
| 2 | `EXIT_MISSING_TOOL` | Required tool not found |
| 3 | `EXIT_ARG_ERROR` | Invalid argument provided |
| 4 | `EXIT_PERMISSION_ERROR` | Permission denied (e.g., /tmp not writable) |

## Code Style

The script uses a consistent comment style for syntax highlighting:

- `#?` - Checks and explanations
- `#~@` - Section headings
- `#>` - Actions
- `#|` - Multiline documentation

## Troubleshooting

### "fd not available" during benchmark
```bash
# Install fd temporarily
nix-shell -p fd --run 'nixos-lib-dir --benchmark'

# Or install permanently
nix-env -iA nixpkgs.fd
```

### Clipboard not working
```bash
# Check which display server you're using
echo $XDG_SESSION_TYPE  # wayland or x11

# For Wayland
nix-env -iA nixpkgs.wl-clipboard

# For X11
nix-env -iA nixpkgs.xclip
# OR
nix-env -iA nixpkgs.xsel

# Verify installation
command -v wl-copy || command -v xclip || command -v xsel
```

### "/tmp is not writable"
```bash
# Check permissions
ls -ld /tmp

# Verify write access
touch /tmp/test && rm /tmp/test
```

### "No directories found"
```bash
# Verify pattern matches something
find /nix/store -type d -path '*-nixos/nixos/lib' | head -n 1

# Try broader pattern
nixos-lib-dir -p '*nixos*/lib' --verbose
```

### Stale cache
```bash
# Force refresh
nixos-lib-dir --refresh-cache

# Or delete cache manually
rm /tmp/nixos-lib-dir

# With verbose output
nixos-lib-dir -f -d
```

## Scripting Examples

### Simple usage
```bash
#!/bin/sh
lib=$(nixos-lib-dir --quiet)
echo "Using NixOS lib: $lib"
```

### With error handling
```bash
#!/bin/sh
if lib=$(nixos-lib-dir --quiet); then
    echo "Found: $lib"
else
    echo "Error: Could not find NixOS lib" >&2
    exit 1
fi
```

### Background update
```bash
#!/bin/sh
# Update cache in background without output
nixos-lib-dir --quiet &
```

### Verbose for debugging
```bash
#!/bin/sh
set -x
lib=$(nixos-lib-dir --verbose --refresh-cache)
echo "Result: $lib"
```

## Development

### Project Structure
```
nixos-lib-dir
├── main()              # Entry point with metadata
├── set_defaults()      # Initialize variables and exit codes
├── parse_args()        # Command-line argument parsing
├── init_environment()  # Tool detection and validation
├── execute()           # Main execution flow
├── check_cache()       # Cache validation
├── use_cache()         # Cache retrieval
├── find_latest()       # Search implementation
├── print_path()        # Output and clipboard handling
└── benchmark()         # Performance testing
```

### Metadata Variables
```sh
_name  # Script name
_docs  # Documentation path
_desc  # Short description
_deps  # Dependencies description
```

### Adding New Features

1. Add variables in `set_defaults()`
2. Add argument parsing in `parse_args()`
3. Implement feature in appropriate function
4. Update help text
5. Test with and without sourcing
6. Update documentation

### Testing

```bash
# Test basic functionality
./nixos-lib-dir

# Test when sourced
. ./nixos-lib-dir

# Test all output modes
./nixos-lib-dir          # silent
./nixos-lib-dir -d       # verbose
./nixos-lib-dir -q       # quiet

# Test all options
./nixos-lib-dir -c /tmp/test -a 5 -p '*nixos/lib' -f
./nixos-lib-dir --benchmark

# Test error handling
./nixos-lib-dir --invalid-option
./nixos-lib-dir -c
./nixos-lib-dir -p 'nonexistent-pattern'
```

## Contributing

Contributions welcome! Please ensure:
- Code follows existing style conventions
- All functions have appropriate comments
- Exit codes are used correctly
- Script works when both executed and sourced
- Changes are tested with and without optional tools
- Documentation is updated

## License

Public domain / Unlicense

## See Also

- [fd](https://github.com/sharkdp/fd) - Fast alternative to find
- [hyperfine](https://github.com/sharkdp/hyperfine) - Command-line benchmarking tool
- [NixOS Manual](https://nixos.org/manual/nixos/stable/) - NixOS documentation
