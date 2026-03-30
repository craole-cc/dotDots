{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) filterAttrs genAttrs mapAttrs;
  inherit (lib.lists) elem filter head init last length;
  inherit (lib.strings) concatStringsSep;
  inherit (_.lists.predicates) isIn;
  inherit (_.lists.transformation) indentedForError;
  inherit (_.applications.enums) categories;
  data = _.filesystem.importers.importAllMerged ./.data {};

  __exports = {
    internal = {
      inherit
        all
        byCategory
        ofCategory
        lookup
        identify
        resolveExec
        mkApps
        ;
    };
    external = {
      appRegistry = all;
    };
  };

  # -- Resolution ──────────────────────────────────────────────────────────────
  listCategories = indentedForError {
    title = "Valid Categories";
    items = categories;
  };

  all =
    mapAttrs (
      name: app: let
        invalid = filter (c: !elem c categories) app.categories;
        count = length invalid;
        quoted = map (c: "'${c}'") invalid;
        humanJoin = items:
          if count == 1
          then head items
          else "${concatStringsSep ", " (init items)} and ${last items}";
      in
        if invalid != []
        then
          throw "${humanJoin quoted} ${
            if count == 1
            then "is an invalid category"
            else "are invalid categories"
          }. ${listCategories}"
        else app
    )
    data;

  ofCategory = cat:
    if !isIn cat categories
    then throw "'${cat}' is not a valid category. ${listCategories}"
    else filterAttrs (_: a: isIn cat a.categories) all;

  byCategory = genAttrs categories ofCategory;

  # -- Lookup ───────────────────────────────────────────────────────────────────

  lookup = name: category: let
    app = all.${name} or (throw "Unknown app '${name}' in registry.");
  in
    if elem category app.categories
    then app
    else throw "'${name}' does not satisfy category '${category}'. Its categories: ${toString app.categories}";

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

  # Wraps a terminal-mode app using the resolved terminal emulator.
  # e.g. yazi via foot → "foot --title yazi -e yazi"
  resolveExec = tty: app:
    if app.needsTerminal or false
    then
      "${tty.names.command}"
      + " ${tty.wrap.titleFlag} ${
        app.names.title or app.names.command
      }"
      + " ${tty.wrap.execFlag} ${app.exec}"
    else app.exec;

  # -- Enrichment ───────────────────────────────────────────────────────────────

  # Enriches the all registry with resolved nix pkg derivations.
  # Falls back gracefully so UI resolution never hard-fails on a missing pkg.
  mkApps = pkgs:
    mapAttrs (name: app: let
      pkg = pkgs.${app.names.package} or null;
    in
      app
      // {inherit pkg;}
      // (
        if pkg != null
        then {version = pkg.version;}
        else {}
      ))
    all;
in
  __exports.internal // {_rootAliases = __exports.external;}
