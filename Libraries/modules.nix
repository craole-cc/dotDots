{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) isAttrs isDerivation mapAttrs;
  inherit (lib.modules) mkDefault;
  inherit (_.filesystem.importers) importAttrset;

  /**
  Recursively applies `mkDefault` to all values in an attribute set.

  Skips values with existing `_type` (like `mkEnableOption` results) to avoid
  overriding special module handling. Preserves derivations unchanged.

  # Type
  recursiveUpdate :: a -> a

  # Arguments
  - `value`: Any Nix value (attrset, primitive, derivation, etc.)

  # Returns
  The input value with `mkDefault` recursively applied to attrset values
  (except `_type`-marked and derivations).

  # Examples
  Basic usage
  recursiveUpdate { enable = true; port = 8080; }

  => { enable = mkDefault true; port = mkDefault 8080; }
  Nested attrsets
  recursiveUpdate {
    services.nginx = {
    enable = true;
    virtualHosts.foo = { enable = false; };
    };
  }

  => Nested mkDefault wrapping
  Skips _type values
  recursiveUpdate {
  enable = lib.mkEnableOption "service"; # _type preserved
  port = 8080; # Gets mkDefault
  }

  => { enable = lib.mkEnableOption "service"; port = mkDefault 8080; }
  Use with resolution
  let cfg = getPackage { pkgs; target = "nginx"; };
  in recursiveUpdate cfg // { extraConfig = "..." }

  => Resolved package + mkDefault-wrapped overrides
  */
  recursiveUpdate = value:
    if value._type or null != null
    then value # Already has special handling, don't wrap it
    else if isAttrs value && !isDerivation value
    then mapAttrs (_: recursiveUpdate) value
    else mkDefault value;

  # Modified recursiveUpdate that handles module options properly
  recursiveUpdateDeep = prev: next:
    if prev._type or null != null
    then prev # Don't modify special types
    else if next._type or null != null
    then next # Special type overrides
    else if prev ? _module && next ? _module
    then prev // next # Module options, merge directly
    else if lib.isAttrs prev && lib.isAttrs next && !lib.isDerivation prev && !lib.isDerivation next
    then lib.recursiveUpdate prev next # Use lib's recursiveUpdate for nested attrsets
    else next;

  # Generator for host configurations
  generateHost = name: config: let
    baseConfig = {
      stateVersion = "25.11";

      paths = {
        dots = mkDefault "/home/craole/.dots";
      };

      # ... other base configurations from your example
      specs = {
        platform = "${config.arch or "x86_64"}-${config.os or "linux"}";
        machine = config.machine or "laptop";
      };

      # ... rest of your base configuration
    };

    # Merge base with host-specific config, handling special cases
    merged = recursiveUpdateDeep baseConfig config;
  in
    merged;

  # Import and generate all hosts
  importHosts = dir: let
    hosts = importAttrset dir;
  in
    mapAttrs generateHost hosts;
in {
  inherit
    importHosts
    generateHost
    recursiveUpdate
    recursiveUpdateDeep
    ;
}
