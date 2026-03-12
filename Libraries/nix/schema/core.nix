{
  _,
  lib,
  ...
}: let
  inherit (_.schema) ui user;
  inherit (lib.attrsets) attrNames attrValues;
  inherit (lib.lists) head;

  exports = {
    internal = {inherit mkHost mkCore hostOrDefault;};
    external = {
      mkCoreSchema = mkCore;
    };
  };

  mkHost = {
    hosts,
    name ? null,
  }:
    if hosts ? ${name}
    then hosts.${name}
    else throw "Host '${name}' not found. Available hosts: ${toString (attrNames hosts)}";

  hostOrDefault = {
    hosts,
    name ? null,
  }:
    if name == null
    then mkHost {inherit hosts name;}
    else if hosts != {}
    then head (attrValues hosts)
    else throw "No hosts available";

  /**
  Enrich a single host with user data, interface normalization, and metadata.
  */
  mkCore = {
    name,
    host,
    users,
  }: let
    enrichedUser = user.enriched {inherit host users;};
    enrichedUI = ui.enriched {
      inherit host;
      user = enrichedUser.data.primary;
    };
    enrichment = {
      inherit name;
      inherit (host.paths) dots;
      system = host.specs.platform or "x86_64-linux";
      users = enrichedUser;
      interface = enrichedUI;
    };
  in
    host // enrichment;
in
  exports.internal // {_rootAliases = exports.external;}
