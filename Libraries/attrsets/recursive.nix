{lib, ...}: let
  inherit (lib.attrsets) isAttrs isDerivation mapAttrs;
  inherit (lib.modules) mkDefault;

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
  update = value:
    if value._type or null != null
    then value # Already has special handling, don't wrap it
    else if isAttrs value && !isDerivation value
    then mapAttrs (_: update) value
    else mkDefault value;

  # Modified recursiveUpdate that handles module options properly
  updateDeep = prev: next:
    if prev._type or null != null
    then prev # Don't modify special types
    else if next._type or null != null
    then next # Special type overrides
    else if prev ? _module && next ? _module
    then prev // next # Module options, merge directly
    else if lib.isAttrs prev && lib.isAttrs next && !lib.isDerivation prev && !lib.isDerivation next
    then lib.update prev next # Use lib's recursiveUpdate for nested attrsets
    else next;
in {
  inherit
    update
    updateDeep
    ;
}
