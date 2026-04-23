{_, ...}: let
  meta = let
    doc = ''
      Application enums (Layer 4).

      Converts the application registry into typed enums, recursively
      walking nested registry trees and wrapping leaf sets with `mkEnum`.

      Provides pre-built enums for shells and interfaces, including
      queried sub-enums with optional nullability overrides.

      Depends on: applications.queries lists.construction.
    '';
    functions = {
      inherit all toEnums;
    };
    exports = {
      local = all // functions;
      alias = {
        toApplicationEnums = toEnums;
      };
    };
  in {
    inherit doc exports functions;
  };

  inherit (_.applications.filters.queries) shell interface;
  inherit (_.applications.registry) isRegistryAttrset;
  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.lists.construction) mkEnum;

  /**
      Recursively convert a registry tree into enums.

      Leaf sets (identified by `isRegistryAttrset`) are wrapped with `mkEnum`
      with `nullable = true`. Intermediate nodes are mapped over recursively.

      # Type
  ```nix
      toEnums :: AttrSet -> Enum | { ${key} :: Enum }
  ```

      # Examples
  ```nix
      toEnums { bash = { categories = [ "shell" ]; }; }
      # => Enum { values = { bash = ... }; nullable = true; ... }

      # Intermediate node — recurses into subtrees
      toEnums { system = { bash = { categories = [ "shell" ]; }; }; }
      # => { system = Enum { ... }; }
  ```
  */
  toEnums = input:
    if isRegistryAttrset input
    then
      mkEnum {
        values = input;
        nullable = true;
      }
    else mapAttrs (_: toEnums) input;

  all = {
    shells =
      toEnums shell
      // {
        queried =
          toEnums shell.queried
          // {
            #? non-nullable override — system shell must always be set
            system = mkEnum {
              values = shell.queried.system;
              nullable = false;
            };
          };
      };
    interface = toEnums interface;
  };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
