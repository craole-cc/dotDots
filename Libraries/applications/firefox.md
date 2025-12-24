# Firefox Browser Configuration Module

## Overview

This module provides comprehensive tools for managing Firefox and Firefox-based browsers (Zen Browser, LibreWolf, Pale Moon) including variant detection, extension management, and Home Manager module resolution.

## Quick Start

```nix
# In your Nix configuration
{ lix, ... }:

{
  # Basic extension installation
  programs.firefox.policies.ExtensionSettings =
    lix.applications.extensionSettings {
      "uBlock0@raymondhill.net" = { pinned = true; };
      "addon@darkreader.org" = {};
    };

  # Browser selection
  browser = lix.applications.getFirefoxModule {
    inherit inputs pkgs;
    variant = "zen twilight";
    policies = { webGui = true; };
  };
}
```

## Core Functions

### `extensionUrl(id: String) → String`

Generates Mozilla Add-ons CDN URL for a given extension ID.

**Arguments:**

- `id`: Firefox extension ID (format: `name@domain` or `{uuid}`)

**Examples:**

```nix
extensionUrl "uBlock0@raymondhill.net"
# => "https://addons.mozilla.org/firefox/downloads/latest/uBlock0@raymondhill.net/latest.xpi"

extensionUrl "{446900e4-71c2-419f-a6a7-df9c091e268b}"
# => "https://addons.mozilla.org/firefox/downloads/latest/{446900e4-71c2-419f-a6a7-df9c091e268b}/latest.xpi"
```

### `extensionEntry({ id: String, pinned: Boolean? }) → AttrSet`

Creates a complete Firefox policy entry for automated extension installation.

**Arguments:**

- `id` (required): Extension ID
- `pinned` (optional, default: `false`): Pin to toolbar

**Returns:**

```nix
{
  install_url = "https://.../latest.xpi";
  installation_mode = "force_installed";
  default_area = "navbar";  # if pinned = true
}
```

**Examples:**

```nix
# Basic installation
extensionEntry { id = "uBlock0@raymondhill.net"; }

# Pinned to toolbar
extensionEntry {
  id = "uBlock0@raymondhill.net";
  pinned = true;
}
```

### `extensionSettings(attrset: AttrSet) → AttrSet`

Batch creates Firefox extension policies from simplified format.

**Arguments:** Attribute set where keys are extension IDs and values are:

- `{}` for default installation
- `{ pinned = true; }` to pin to toolbar
- Custom attribute sets for advanced configuration

**Examples:**

```nix
extensionSettings {
  "uBlock0@raymondhill.net" = {};
  "addon@darkreader.org" = { pinned = true; };
  "some@extension.org" = {
    install_url = "https://custom.url/extension.xpi";
    installation_mode = "normal_installed";
  };
}
```

### `detectVariant(input: String) → String?`

Parses user strings to detect and normalize browser variant names.

**Supported Input Patterns:**

| Category              | Keywords                                                         | Result               |
| --------------------- | ---------------------------------------------------------------- | -------------------- |
| **Firefox ESR**       | `esr`, `extend`, `stable`, `support`, `reproducible`, `twilight` | `firefox-esr`        |
| **Firefox Beta**      | `beta`, `nightly`, `unstable`, `latest`                          | `firefox-beta`       |
| **Developer Edition** | `dev`, `development`, `devedition`, `dev-edition`, `developer`   | `firefox-devedition` |
| **Zen Twilight**      | `zen`, `twilight`, `zen twilight`                                | `zen-twilight`       |
| **Zen Beta**          | `zen beta`, `zen nightly`, `zen unstable`                        | `zen-beta`           |
| **LibreWolf**         | `libre`, `wolf`                                                  | `librewolf-bin`      |
| **Pale Moon**         | `pale`, `moon`                                                   | `palemoon-bin`       |
| **Default**           | Any unrecognized input                                           | `firefox`            |

**Examples:**

```nix
detectVariant "esr"           # => "firefox-esr"
detectVariant "zen beta"      # => "zen-beta"
detectVariant "libre"         # => "librewolf-bin"
detectVariant ""              # => null
```

### `resolveModule({ inputs, pkgs, system?, variant?, policies? }) → AttrSet`

Resolves complete browser configuration including packages, Home Manager modules, and policy settings.

**Arguments:**

- `inputs`: Flake inputs containing browser sources
- `pkgs`: Nixpkgs instance for package resolution
- `system` (optional): Target system (default: `"x86_64-linux"`)
- `variant` (optional): Browser variant string (default: `"firefox"`)
- `policies` (optional): Configuration policies

**Policies Attribute Set:**

- `webGui` (Bool): Enable web GUI module (required for activation)
- `dev` (Bool): Force developer edition variant
- `devGui` (Bool): Same as `dev`, alternative naming

**Returns:**

```nix
{
  program = "firefox";  # or "zen-browser", etc.
  package = <derivation>;  # Resolved browser package
  variant = "firefox-esr";  # Normalized variant name
  allowed = true;  # Whether configuration is allowed
  module = <module>;  # Home Manager module (Zen Browser only)
}
```

**Examples:**

```nix
# Firefox ESR
resolveModule {
  inherit inputs pkgs;
  variant = "esr";
  policies = { webGui = true; };
}

# Zen Browser with flake integration
resolveModule {
  inherit inputs pkgs;
  system = "x86_64-linux";
  variant = "zen twilight";
  policies = { webGui = true; };
}

# Developer edition
resolveModule {
  inherit inputs pkgs;
  variant = "firefox";
  policies = {
    webGui = true;
    dev = true;
  };
}
```

### `zenVariant(variant: String) → String?`

Extracts Zen Browser variant from user input.

**Returns:**

- `"beta"` for beta/nightly/unstable variants
- `"twilight"` for stable/default variants
- `null` if not a Zen Browser variant

**Examples:**

```nix
zenVariant "zen"            # => "twilight"
zenVariant "zen beta"       # => "beta"
zenVariant "firefox"        # => null
```

## Root Aliases

For convenience, the module provides these aliases at the root level:

| Alias                        | Maps to             | Description                     |
| ---------------------------- | ------------------- | ------------------------------- |
| `mkFirefoxExtensionUrl`      | `extensionUrl`      | Generate extension URL          |
| `mkFirefoxExtensionEntry`    | `extensionEntry`    | Create extension policy entry   |
| `mkFirefoxExtensionSettings` | `extensionSettings` | Batch create extension settings |
| `detectFirefoxVariant`       | `detectVariant`     | Detect browser variant          |
| `getFirefoxModule`           | `resolveModule`     | Resolve browser configuration   |

## Supported Browsers

### Firefox Variants

- **Stable**: Regular Firefox release
- **ESR** (Extended Support Release): Long-term support version
- **Beta**: Pre-release testing version
- **Nightly**: Daily development builds
- **Developer Edition**: Version with developer tools

### Zen Browser

- **Twilight**: Stable release
- **Beta**: Beta/nightly builds

### Other Firefox-based Browsers

- **LibreWolf**: Privacy-focused fork
- **Pale Moon**: Firefox fork with classic UI

## Zen Browser Flake Integration

The module automatically detects Zen Browser from these flake input names:

- `firefoxZen`
- `zenBrowser`
- `zen-browser`
- `zen_browser`
- `twilight`
- `zen`

**Expected flake structure:**

```nix
inputs.zen-browser = {
  url = "github:...";
  packages.x86_64-linux = {
    twilight = <derivation>;
    beta = <derivation>;
  };
  homeModules = {
    twilight = <module>;
    beta = <module>;
  };
};
```

## Finding Extension IDs

1. Open Firefox and navigate to `about:support`
1. Scroll to "Extensions" section
1. Copy the ID from the extension's entry
1. Alternatively, check the extension's page URL: `addons.mozilla.org/<*>/addon/<id>/`

## Use Cases

### 1. Declarative Extension Management

```nix
# Home Manager configuration
{ lix, ... }:

{
  programs.firefox = {
    enable = true;
    policies = {
      ExtensionSettings = lix.applications.extensionSettings {
        "uBlock0@raymondhill.net" = { pinned = true; };
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {};
      };
    };
  };
}
```

### 2. Dynamic Browser Selection

```nix
# Choose browser based on user preference
{ lix, inputs, pkgs, ... }:

let
  userPreference = "zen twilight";
  browser = lix.applications.getFirefoxModule {
    inherit inputs pkgs;
    variant = userPreference;
    policies = { webGui = true; };
  };
in {
  # Use browser.package, browser.module, etc.
}
```

### 3. Automated Deployment

```nix
# Deploy Firefox with extensions in NixOS
{ lix, ... }:

{
  programs.firefox = {
    enable = true;
    package = pkgs.firefox-esr;
    policies = {
      ExtensionSettings = lix.applications.extensionSettings {
        "uBlock0@raymondhill.net" = { pinned = true; };
        "addon@darkreader.org" = {};
      };
      # Other policies...
    };
  };
}
```

## Notes

1. **Extension ID Format**: Varies (often `@author.domain` or `{uuid}`)
1. **URL Format**: Always points to latest published version
1. **Zen Browser**: Requires special flake integration
1. **Policy Activation**: Requires `webGui = true` for module activation
1. **Developer Edition**: Can be forced via `dev` or `devGui` policy flags

## Troubleshooting

### Extension Not Installing

- Verify extension ID is correct
- Check if extension is available on Mozilla Add-ons
- Ensure policies are properly formatted

### Zen Browser Not Found

- Verify flake input exists with correct name
- Check that packages and homeModules are structured correctly
- Ensure system architecture matches (`x86_64-linux` by default)

### Variant Detection Issues

- Input is case-insensitive but must match supported keywords
- Use `detectFirefoxVariant` function to test detection
- Check if variant is supported in your nixpkgs version

## Related Modules

- `lix.applications.chromium`: Chromium browser utilities
- `lix.generators.core`: NixOS configuration generators
- `lix.generators.home`: Home Manager configuration helpers

---

_Last updated: $(date)_ _Module version: 1.0.0_
