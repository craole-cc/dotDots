{
  _,
  lib,
  ...
}: let
  __exports = {
    internal = {inherit lookup identify resolveExec mkApps;};
    external.applicationOps = __exports.internal;
  };

  inherit (lib.attrsets) mapAttrs;
  inherit (lib.lists) elem;
  inherit (_.applications.registry) all;
  inherit (_.applications.enums.constants) categories;

  lookup = name: category: let
    app = all.${name} or (throw "Unknown app '${name}' in registry.");
  in
    if categories.validator.check category && elem category app.categories
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

  resolveExec = tty: app:
    if app.needsTerminal or false
    then
      "${tty.names.command}"
      + " ${tty.wrap.titleFlag} ${app.names.title or app.names.command}"
      + " ${tty.wrap.execFlag} ${app.exec}"
    else app.exec;

  mkApps = pkgs:
    mapAttrs (_: app: let
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
