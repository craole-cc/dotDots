{
  _,
  __moduleDir,
  __moduleName,
  ...
}: let
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
    else mapAttrs (_: subtree: toEnums subtree) input;

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
  _.meta.mkModuleExports {
    directory = __moduleDir;
    filename = __moduleName;
    doc = ''
      Application enums (Layer 4).

      Converts the application registry into typed enums, recursively
      walking nested registry trees and wrapping leaf sets with `mkEnum`.
      Provides pre-built enums for shells and interfaces, including
      queried sub-enums with optional nullability overrides.

      Depends on: applications.queries lists.construction.
    '';

    functions = all // {inherit all toEnums;};
  }
