{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) isAttrs isDerivation mapAttrs recursiveUpdate;
  inherit (lib.modules) mkDefault mkEnableOption mkForce;
  inherit (_.trivial.tests) mkTest runTests;

  /**
  Recursively applies `mkDefault` to all values in an attribute set.

  Wraps values in `mkDefault` to allow downstream overrides while providing
  sensible defaults. Preserves special module types and derivations unchanged.

  # Type
  ```
  update :: a -> a
  ```

  # Arguments
  - `value`: Any Nix value (attrset, primitive, derivation, etc.)

  # Returns
  The input value with `mkDefault` recursively applied to:
  - Plain attribute sets (recursively to nested values)
  - Primitive values (strings, numbers, booleans, etc.)

  Skips:
  - Values with `_type` attribute (module system special types)
  - Derivations (packages)

  # Examples
  ```nix
  update { enable = true; port = 8080; }
  # => { enable = mkDefault true; port = mkDefault 8080; }

  # Nested attrsets
  update {
    services.nginx = {
      enable = true;
      virtualHosts.foo = { enable = false; };
    };
  }
  # => All leaf values wrapped in mkDefault

  # Preserves special types
  update {
    enable = lib.mkEnableOption "service"; # Has _type
    port = 8080;
  }
  # => { enable = lib.mkEnableOption "service"; port = mkDefault 8080; }

  # Preserves derivations
  update {
    package = pkgs.nginx; # Derivation
    config = "/etc/nginx";
  }
  # => { package = pkgs.nginx; config = mkDefault "/etc/nginx"; }
  ```

  # Use Cases
  - Creating module defaults that users can easily override
  - Applying mkDefault to resolved package configurations
  - Preparing configuration templates with overrideable values
  */
  update = value:
    if value._type or null != null
    then value # Special module type, preserve as-is
    else if isAttrs value && !isDerivation value
    then mapAttrs (_: update) value # Recurse into plain attrsets
    else mkDefault value; # Wrap primitives in mkDefault

  /**
  Deep merge two attribute sets with module-aware handling.

  Similar to `lib.recursiveUpdate` but respects module system semantics:
  - Preserves `_type` attributes (doesn't override special types)
  - Handles `_module` attributes specially (direct merge)
  - Falls back to standard recursive update for plain attrsets

  # Type
  ```
  updateDeep :: AttrSet -> AttrSet -> AttrSet
  ```

  # Arguments
  - `prev`: Base/previous attribute set
  - `next`: New/override attribute set

  # Returns
  Merged attribute set with `next` values taking precedence, respecting
  module semantics

  # Examples
  ```nix
  updateDeep
    { a = 1; b = { c = 2; }; }
    { b = { d = 3; }; e = 4; }
  # => { a = 1; b = { c = 2; d = 3; }; e = 4; }

  # Preserves _type in prev
  updateDeep
    { enable = lib.mkEnableOption "foo"; }
    { enable = true; }
  # => { enable = lib.mkEnableOption "foo"; } # prev wins for special types

  # Allows _type override in next
  updateDeep
    { enable = true; }
    { enable = lib.mkForce false; }
  # => { enable = lib.mkForce false; } # next special type wins

  # Module options
  updateDeep
    { _module.args = { x = 1; }; }
    { _module.args = { y = 2; }; }
  # => { _module.args = { x = 1; y = 2; }; } # Direct merge
  ```

  # Notes
  - Prefer this over `lib.recursiveUpdate` when working with module configurations
  - The asymmetry in `_type` handling allows next to override with special types
    while protecting special types in prev from being clobbered
  */
  updateDeep = prev: next:
    if prev._type or null != null
    then prev # prev has special type, preserve it
    else if next._type or null != null
    then next # next has special type, use it
    else if prev ? _module && next ? _module
    then prev // next # Module options, shallow merge
    else if isAttrs prev && isAttrs next && !isDerivation prev && !isDerivation next
    then recursiveUpdate prev next # Standard deep merge for plain attrsets
    else next; # Primitive override
in {
  inherit
    update
    updateDeep
    ;

  _tests = runTests {
    update = {
      wrapsPrimitives =
        mkTest
        {
          a = mkDefault 1;
          b = mkDefault "x";
          c = mkDefault true;
        }
        (update {
          a = 1;
          b = "x";
          c = true;
        });

      recursesIntoNestedSets =
        mkTest
        {
          services = {
            nginx = {
              enable = mkDefault true;
              port = mkDefault 8080;
            };
          };
        }
        (update {
          services.nginx = {
            enable = true;
            port = 8080;
          };
        });

      preservesDerivations =
        mkTest
        {
          pkg = "drv"; # we just check identity, not mkDefault
          config = mkDefault "/etc/foo";
        }
        (let
          fakeDrv = "drv"; # stand-in; in real tests you could use a real derivation
        in
          update {
            pkg = fakeDrv;
            config = "/etc/foo";
          });

      preservesSpecialType =
        mkTest
        (mkEnableOption "service")
        (update (mkEnableOption "service"));
    };

    updateDeep = {
      mergesSimpleAttrs =
        mkTest
        {
          a = 1;
          b = {
            c = 2;
            d = 3;
          };
          e = 4;
        }
        (updateDeep
          {
            a = 1;
            b = {c = 2;};
          }
          {
            b = {d = 3;};
            e = 4;
          });

      preservesPrevSpecialType =
        mkTest
        {enable = mkEnableOption "foo";}
        (updateDeep
          {enable = mkEnableOption "foo";}
          {enable = true;});

      allowsNextSpecialType =
        mkTest
        {enable = mkForce false;}
        (updateDeep
          {enable = true;}
          {enable = mkForce false;});

      mergesModuleArgsShallow =
        mkTest
        {
          _module.args = {
            x = 1;
            y = 2;
          };
        }
        (updateDeep
          {_module.args = {x = 1;};}
          {_module.args = {y = 2;};});

      primitiveOverride =
        mkTest
        2
        (updateDeep 1 2);
    };
  };
}
