# DOTS PowerShell Profile Loader

A flexible, configuration-driven PowerShell profile loader that provides fine-grained control over script and module loading across multiple directories and environments.

## Features

- **Multi-format configuration support** (JSON, TOML, plain text)
- **Flexible file discovery** with customizable configuration file names
- **Hierarchical loading** with global and local configuration
- **Advanced exclusion patterns** (global and local)
- **Custom load orders** with multiple specification methods
- **Module path management** with automatic environment variable creation
- **Smart content detection** for configuration files
- **Comprehensive debugging** and logging support

## Quick Start

1. Place the profile loader script in your PowerShell profile directory
1. Create a `.dotsrc` (or `.dots.json`) configuration file
1. Define your includes and module structure
1. Load your profile and watch the magic happen!

## Configuration

### Main Configuration File

The loader searches for configuration files in this order:

- `.dotsrc`
- `.dots.json`
- `.dots.toml`
- `.dots.conf`
- `config.json`
- `dots.json`

The format is auto-detected based on content structure.

### Basic Configuration Structure

```json
{
  "Options": {
    "Tag": ">>= DOTS =<<",
    "Verbosity": "Info",
    "VerbosePreference": "Continue",
    "DebugPreference": "Continue",
    "InformationPreference": "Continue",
    "WarningPreference": "Continue",
    "ErrorActionPreference": "Continue"
  },
  "ExperimentalFeatures": ["PSFeedbackProvider"],
  "Excludes": [
    "review",
    "tmp",
    "temp",
    "archive",
    "backup",
    "*.bac",
    "*.bak",
    "* copy*",
    "*.old"
  ],
  "OrderFiles": [".dotsrc", ".dots.json", ".dots.conf", "config.json"],
  "Includes": [
    {
      "path": "Bin\\powershell",
      "modules": ["components", "output"]
    },
    {
      "path": "Configuration\\powershell",
      "modules": []
    },
    {
      "path": "Utils\\powershell",
      "modules": ["Base", "Admin", "Tools"]
    }
  ]
}
```

## Configuration Options

### Options Section

| Option | Description | Default |
| ----------------------- | ---------------------------------- | -------------------- |
| `Tag` | Prefix for all log messages | `">>= DOTS =<<"` |
| `Verbosity` | Logging verbosity level | `"Info"` |
| `VerbosePreference` | PowerShell verbose preference | `"SilentlyContinue"` |
| `DebugPreference` | PowerShell debug preference | `"SilentlyContinue"` |
| `InformationPreference` | PowerShell information preference | `"SilentlyContinue"` |
| `WarningPreference` | PowerShell warning preference | `"SilentlyContinue"` |
| `ErrorActionPreference` | PowerShell error action preference | `"Continue"` |

### Excludes

Global exclusion patterns applied to all loading operations. Supports:

- **Exact matches**: `"temp"`
- **Wildcards**: `"*.bak"`, `"* copy*"`
- **Regex patterns**: `"test.*"`

### OrderFiles

Customizable list of configuration file names to search for in directories. Default:

```json
[
  ".dotsrc",
  ".dots.json",
  ".dots.toml",
  ".dots.conf",
  ".dots.txt",
  "config.json"
]
```

### Includes

Array of path configurations defining what to load.

#### Include Configuration

```json
{
  "path": "relative\\path\\from\\DOTS\\env\\var",
  "modules": ["module1", "module2"]
}
```

**Path**: Relative path from `$env:DOTS` environment variable **Modules**: Array of module/directory names to load

#### Module Loading Behavior

| Modules Value | Behavior |
| ------------------ | ---------------------------- |
| `["mod1", "mod2"]` | Load only specified modules |
| `[]` | Load ALL modules in the path |
| `null` or missing | Skip loading entirely |

## Local Configuration

Each directory can have its own configuration file to override global behavior.

### Local Configuration Files

The loader searches for local config files using the `OrderFiles` setting:

- `.dotsrc`
- `.dots.json`
- `.dots.conf`
- `config.json`
- etc.

### Local Configuration Options

#### Skip Directory Entirely

**JSON Format:**

```json
{
  "skip": true
}
```

**Plain Text:**

```
skip
```

**Empty File:** Files are no longer treated as skip by default - empty files allow normal loading.

#### Local Excludes

**JSON Format:**

```json
{
  "Excludes": ["debug*", "*.tmp", "old-*"]
}
```

Local excludes are combined with global excludes for comprehensive filtering.

#### Custom Load Order

**JSON Format:**

```json
{
  "Includes": ["core.ps1", "utils.ps1", "helpers.ps1"]
}
```

**Plain Text Format:**

```
core.ps1
utils.ps1
# Comments are supported
helpers.ps1
```

#### Combined Configuration

```json
{
  "Includes": ["important.ps1", "secondary.ps1"],
  "Excludes": ["debug*", "test*"]
}
```

## Loading Behavior

### Auto-Discovery Mode

When no local configuration is found:

1. Load `.psm1` files first (alphabetically)
1. Load `.ps1` files second (alphabetically)
1. Process subdirectories recursively (alphabetically)

### Custom Load Order Mode

When local configuration specifies includes:

1. Process items in the specified order
1. Support multiple item types:
   - **Direct files**: `"script.ps1"`
   - **File patterns**: `"*.ps1"`, `"utils*.ps1"`
   - **Path patterns**: `"subfolder/*.ps1"`
   - **Directory names**: `"components"`

### Exclusion Processing

Exclusions are processed at every level:

1. **Global excludes** from main configuration
1. **Local excludes** from directory configuration
1. **Combined pattern matching** using wildcards and regex
1. **Applied to both files and directories**

## Environment Variables

The loader automatically creates environment variables for each include:

```json
{
  "path": "Bin\\powershell"
}
```

Creates:

- `$env:DOTS_BIN` → `D:\Path\To\.dots\Bin`
- `$env:DOTS_BIN_PS` → `D:\Path\To\.dots\Bin\powershell`
- `$Global:DOTS_BIN` → PowerShell variable
- `$Global:DOTS_BIN_PS` → PowerShell variable

## Advanced Features

### Multi-Format Support

Configuration files are automatically detected by content:

**JSON Detection:**

- Content starts with `{` and ends with `}`
- File extension is `.json`

**TOML Detection:**

- File extension is `.toml` (parsing will be implemented)

**Plain Text:**

- Everything else treated as plain text includes/load order

### Global Function Scoping

All functions defined in loaded scripts are automatically made available in the global scope, ensuring they're accessible throughout your PowerShell session.

### Smart File Filtering

The loader includes intelligent filtering:

- **Configuration File Exclusion**: Config files are never loaded as scripts
- **Extension Validation**: Only `.ps1` and `.psm1` files are loaded

### PSModulePath Management

Include paths are automatically added to `$env:PSModulePath` for proper module discovery.

## Examples

### Basic Setup

**.dotsrc:**

```json
{
  "Includes": [
    {
      "path": "PowerShell",
      "modules": []
    }
  ]
}
```

This loads all modules from `$env:DOTS\PowerShell\`.

### Selective Loading

**.dotsrc:**

```json
{
  "Includes": [
    {
      "path": "Scripts\\PowerShell",
      "modules": ["Core", "Utils", "Admin"]
    }
  ]
}
```

This loads only the Core, Utils, and Admin modules.

### Complex Configuration

**.dotsrc:**

```json
{
  "Options": {
    "DebugPreference": "Continue"
  },
  "Excludes": ["*.bak", "temp*", "review"],
  "Includes": [
    {
      "path": "Core\\PowerShell",
      "modules": ["Base"]
    },
    {
      "path": "Tools\\PowerShell",
      "modules": []
    },
    {
      "path": "Projects\\PowerShell",
      "modules": ["Active", "Utils"]
    }
  ]
}
```

**Local Config** (`Tools\PowerShell\Debug\.dotsrc`):

```json
{
  "skip": true
}
```

**Local Config** (`Tools\PowerShell\Experimental\.dotsrc`):

```json
{
  "Excludes": ["*.alpha.*", "broken*"]
}
```

## Debugging

Enable detailed logging by setting debug preferences in your configuration:

```json
{
  "Options": {
    "DebugPreference": "Continue",
    "VerbosePreference": "Continue",
    "InformationPreference": "Continue"
  }
}
```

### Debug Output Example

```
>>= DOTS =<< Initializing PowerShell environment...
DEBUG: >>= DOTS =<< Found 3 include configurations
DEBUG: >>= DOTS =<< Processing path: Core\PowerShell => D:\dots\Core\PowerShell
DEBUG: >>= DOTS =<< Loading 1 modules: Base
DEBUG: >>= DOTS =<<   Loading: Base
DEBUG: >>= DOTS =<<   Local excludes: *.tmp, debug*
DEBUG: >>= DOTS =<<   Using auto-discovery
DEBUG: >>= DOTS =<<     ✓ core.ps1 (script)
DEBUG: >>= DOTS =<<     ⊘ Excluded by pattern '*.tmp': temp.tmp
DEBUG: >>= DOTS =<<     ✓ utils.psm1 (module)
```

## Troubleshooting

### Common Issues

**Configuration not found:**

- Ensure config file is in the same directory as the loader script
- Check file name matches the `OrderFiles` list
- Verify JSON syntax if using JSON format

**Modules not loading:**

- Check `$env:DOTS` environment variable is set
- Verify path exists and is accessible
- Review exclude patterns for conflicts
- Enable debug logging to trace loading process

**Scripts failing to load:**

- Check for syntax errors in individual scripts
- Verify file permissions
- Look for `Export-ModuleMember` in `.ps1` files (move to `.psm1`)

### Performance Tips

- Use specific module lists instead of loading everything (`modules: []`)
- Leverage local excludes to filter out unnecessary files
- Organize scripts into logical directory structures
- Use `.psm1` files for reusable functions

## License

This project is provided as-is for educational and practical use in PowerShell environments.
