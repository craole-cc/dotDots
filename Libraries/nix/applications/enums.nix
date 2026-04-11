{_, ...}: let
  __doc = ''
    Application enums (Layer 4).

    Converts the application registry into typed enums, recursively
    walking nested registry trees and wrapping leaf sets with `mkEnum`.
    Provides pre-built enums for shells and interfaces, including
    queried sub-enums with optional nullability overrides.

    Depends on: _.applications.filters.queries, _.lists.construction
  '';

  __exports = {
    internal = enums;
    external.applicationEnums = enums;
  };

  __imports = {
    inherit (_.attrsets.access) attrValues;
    inherit (_.attrsets.transformation) mapAttrs;
    inherit (_.lists.access) head;
    inherit (_.lists.construction) mkEnum;
    inherit (_.types.predicates) isAttrs;
    inherit (_.applications.filters.queries) shell interface;
  };

  /**
      Return `true` when `tree` is a non-empty attribute set whose first value
      looks like a registry entry (i.e. is an attrset containing `categories`).

      Used to distinguish leaf registry sets from intermediate grouping nodes
      during recursive enum construction.

      # Type
  ```nix
      isRegistryAttrset :: AttrSet -> bool
  ```

      # Examples
  ```nix
      isRegistryAttrset { bash = { categories = [ "shell" ]; }; }
      # => true

      # Intermediate grouping node — values are not registry entries
      isRegistryAttrset { system = { bash = { categories = [ "shell" ]; }; }; }
      # => false

      isRegistryAttrset {}
      # => false
  ```
  */
  isRegistryAttrset = with __imports;
    tree:
      (tree != {})
      && (
        let
          firstVal = head (attrValues tree);
        in
          isAttrs firstVal && firstVal ? categories
      );

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
  toEnums = with __imports;
    input:
      if isRegistryAttrset input
      then
        mkEnum {
          values = input;
          nullable = true;
        }
      else mapAttrs (_: subtree: toEnums subtree) input;

  enums = with __imports; {
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
  __exports.internal
  // {
    _rootAliases = __exports.external;
    inherit __doc;
  }
