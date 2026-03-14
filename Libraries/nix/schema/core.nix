{
  _,
  lib,
  ...
}: let
  inherit (_.schema._) mkUI mkHome mkLocale mkHardware;
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
    enrichedUser = mkHome {inherit host users;};
    enrichedUI = mkUI {
      inherit host;
      user = enrichedUser.data.primary;
    };
    enrichedLocale = mkLocale {
      inherit host;
      user = enrichedUser.data.primary;
    };
    enrichedHardware = mkHardware {inherit host;};
    enrichment = {
      inherit name;
      inherit (host.paths) dots;
      system = host.specs.platform or "x86_64-linux";
      users = enrichedUser;
      interface = enrichedUI;
      localization = enrichedLocale;
      hardware = enrichedHardware;
    };
  in
    host // enrichment;
in
  exports.internal // {_rootAliases = exports.external;}
