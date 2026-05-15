{_, ...}: let
  meta = let
    doc = ''
      Application registry data (Layer 0).

      Provides normalized application records from `./.data`, with consistent
      `categories` (list), `channel`/`family` (optional) fields. Supplies
      primitive tree inspection for recursive processing, validated registry
      lookup, and registry-derived identification metadata.

      Depends on: applications.primitives filesystem.importers.
    '';
    functions = {
      inherit
        all
        mkRegistry
        importRegistry
        isRegistryAttrset
        lookup
        identify
        ;
    };
    exports = {
      local = all // functions;
      alias = {};
    };
  in {
    inherit doc exports functions;
  };

  inherit (_.applications.primitives) normalizeList normalizeOptional;
  inherit (_.attrsets.access) attrValues;
  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.filesystem.importers) importAllMerged;
  inherit (_.lists.access) head;
  inherit (_.lists.predicates) elem;
  inherit (_.types.predicates) isAttrs;

  /**
      Normalize raw registry data into consistent application records.

      Ensures `categories` is always a list (empty if absent/missing) and
      `channel`/`family` fields are normalized optionals (null if emptyish).

      # Type
  ```nix
      mkRegistry :: AttrSet -> AttrSet
  ```

      # Examples
  ```nix
      mkRegistry {
        bash = { categories = "shell"; channel = ""; };
      }
      # => {
      #      bash = {
      #        categories = [ "shell" ];
      #        channel = null;
      #      };
      #    }
  ```
  */
  mkRegistry = data:
    mapAttrs (
      _: app:
        app
        // {
          categories = normalizeList (app.categories or []);
          channel = normalizeOptional (app.channel or null);
          family = normalizeOptional (app.family or null);
        }
    )
    data;

  /**
      Import and normalize registry data from path.

      Combines `importAllMerged` with `mkRegistry` normalization.

      # Type
  ```nix
      importRegistry :: path -> AttrSet
  ```
  */
  importRegistry = path: mkRegistry (importAllMerged path {});

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
  isRegistryAttrset = tree:
    (tree != {})
    && (
      let
        firstVal = head (attrValues tree);
      in
        isAttrs firstVal && firstVal ? categories
    );

  /**
      Lookup an application by name and validate category membership.

      Throws if the app is unknown or does not belong to `category`.

      # Type
  ```nix
      lookup :: string -> string -> AppRecord
  ```
  */
  lookup = name: category: let
    app = all.${name} or (throw "Unknown app '${name}' in registry.");
  in
    if elem category (app.categories or [])
    then app
    else throw "'${name}' does not satisfy category '${category}'. Its categories: ${toString (app.categories or [])}";

  /**
      Derive window-identification metadata from a registry entry.

      Returns prioritized matching strategies based on `app.names`.

      # Type
  ```nix
      identify :: AppRecord -> [{ type :: string, value :: string }] | null
  ```
  */
  identify = app:
    if app.names ? title
    then [
      {
        type = "title";
        value = app.names.title;
      }
      {
        type = "initialTitle";
        value = app.names.title;
      }
    ]
    else if app.names ? class
    then [
      {
        type = "class";
        value = app.names.class;
      }
    ]
    else null;

  all = importRegistry ./.data;
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
