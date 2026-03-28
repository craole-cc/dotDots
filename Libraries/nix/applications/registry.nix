{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) filterAttrs genAttrs mapAttrs;
  inherit (lib.lists) elem filter;
  inherit (_.lists.predicates) isIn;
  inherit (_.applications.enums) categories;
  all = _.filesystem.importers.importAllMerged ./.data {};

  __exports = {
    internal = {
      inherit
        # all
        # validated
        ofCategory
        lookupApp
        wmMatch
        resolveExec
        mkApps
        ;
      all = validated;
    };
    external = {
      appRegistry = validated;
    };
  };

  # ── Validation ──────────────────────────────────────────────────────────────

  validated =
    mapAttrs (
      name: app: let
        bad = filter (c: !elem c categories) app.categories;
      in
        if bad != []
        then throw "Unknown categories in '${name}': ${toString bad}"
        else app
    )
    all;

  # ── Lookup ───────────────────────────────────────────────────────────────────
  byCategory = genAttrs categories ofCategory;
  ofCategory = cat:
    filterAttrs (_: a: isIn cat a.categories) validated;

  lookupApp = name: category: let
    app = validated.${name} or (throw "Unknown app '${name}' in registry.");
  in
    if elem category app.categories
    then app
    else throw "'${name}' does not satisfy category '${category}'. Its categories: ${toString app.categories}";

  # ── WM Identity ──────────────────────────────────────────────────────────────

  # Produces the match expr a WM uses to find an existing window.
  # class takes priority over title; returns null for builtin/launcher-only apps.
  wmMatch = app:
    if app.names ? title
    then {
      type = "title";
      value = app.names.title; # Title then InitialTitle
    }
    else if app.names ? class
    then {
      type = "class";
      value = app.names.class;
    }
    else null;

  # ── Exec Resolution ──────────────────────────────────────────────────────────

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

  # ── Enrichment ───────────────────────────────────────────────────────────────

  # Enriches the validated registry with resolved nix pkg derivations.
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
    validated;
in
  __exports.internal // {_rootAliases = __exports.external;}
