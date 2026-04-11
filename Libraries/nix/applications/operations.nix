{
  _,
  __moduleDir,
  ...
}: let
  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.lists.predicates) elem;
  inherit (_.applications) registry;
  inherit (_.applications.enums.constants) categories;
  inherit (_.applications.primitives) toValue;

  /**
  Lookup application by name and validate category membership.

  Throws if unknown app or category mismatch.

  # Type
  ```nix
  lookup :: string -> string -> AppRecord
  ```

  # Examples
  ```nix
  lookup "zen" "browser"
  # => registry.zen (validated)
  ```
  */
  lookup = name: category: let
    app = registry.${name} or (throw "Unknown app '${name}' in registry.");
  in
    if categories.validator.check category && elem category app.categories
    then app
    else throw "'${name}' does not satisfy category '${category}'. Its categories: ${toString app.categories}";

  /**
  Derive UI identification metadata from app.names.

  Returns identification strategies prioritized by specificity.

  # Type
  ```nix
  identify :: AppRecord -> [{type :: string; value :: string}] | null
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

  /**
  Resolve executable command string for given TTY wrapper.

  Wraps `needsTerminal=true` apps with TTY launcher.

  # Type
  ```nix
  resolveExec :: TtyRecord -> AppRecord -> string
  ```
  */
  resolveExec = tty: app:
    if
      toValue {
        field = "needsTerminal";
        default = false;
      }
      app
    then
      "${tty.names.command}"
      + " ${tty.wrap.titleFlag} ${app.names.title or app.names.command}"
      + " ${tty.wrap.execFlag} ${app.exec}"
    else app.exec;

  /**
  Enrich registry with package lookups and versions.

  Maps over registry, injecting `pkg` and `version` from `pkgs.${name}`.

  # Type
  ```nix
  mkApps :: Pkgs -> AttrSet
  ```
  */
  mkApps = pkgs:
    mapAttrs (
      _: app: let
        pkg = pkgs.${app.names.package} or null;
      in
        app
        // {inherit pkg;}
        // (
          if pkg != null
          then {version = pkg.version;}
          else {}
        )
    )
    registry;
in
  _.meta.mkModuleExports {
    directory = __moduleDir;
    doc = ''
      Application runtime operations (Layer 5).

      Provides higher-level operations that consume normalized registry data
      and produce executable artifacts: validated lookups, UI identification,
      resolved command strings, and package-enriched app records.

      Depends on: applications.registry applications.enums applications.primitives.
    '';

    functions = {inherit lookup identify resolveExec mkApps;};
  }
