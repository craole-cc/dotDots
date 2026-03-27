{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) filterAttrs mapAttrs;
  inherit (lib.lists) elem filter;
  inherit (_.applications.enums) appCategories;
  inherit (_.applications) registry;

  __exports = {
    internal = {
      inherit
        registry
        validated
        appsWithCategory
        lookupApp
        wmMatch
        resolveExec
        mkApps
        ;
    };
    external = __exports.internal;
  };

  # ── Validation ──────────────────────────────────────────────────────────────

  validated =
    mapAttrs (
      name: app: let
        bad = filter (c: !elem c appCategories) app.categories;
      in
        if bad != []
        then throw "Unknown categories in '${name}': ${toString bad}"
        else app
    )
    registry;

  # ── Lookup ───────────────────────────────────────────────────────────────────

  appsWithCategory = cat:
    filterAttrs (_: a: elem cat a.categories) validated;

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
    if app.names ? class
    then {
      type = "class";
      value = app.names.class;
    }
    else if app.names ? title
    then {
      type = "title";
      value = app.names.title;
    }
    else null;

  # ── Exec Resolution ──────────────────────────────────────────────────────────

  # Wraps a terminal-mode app using the resolved terminal emulator.
  # e.g. yazi via foot → "foot --title yazi -e yazi"
  resolveExec = terminalApp: app:
    if app.needsTerminal or false
    then
      "${terminalApp.names.command}"
      + " ${terminalApp.wrap.titleFlag} ${app.names.title or app.names.command}"
      + " ${terminalApp.wrap.execFlag} ${app.exec}"
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
