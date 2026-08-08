{
  _,
  lib,
  ...
}: let
  inherit
    (_.schema._)
    mkUI
    mkHome
    mkLocale
    mkHardware
    ;
  inherit (lib.attrsets) attrNames attrValues;
  inherit (lib.lists) head;

  __exports = {
    internal = {inherit mkHost mkCore hostOrDefault;};
    external = {
      mkCoreSchema = mkCore;
    };
  };

  mkHost = {
    hosts,
    name ? null,
  }:
    hosts.${name} or (throw "Host '${name}' not found. Available hosts: ${toString (attrNames hosts)}");

  hostOrDefault = {
    hosts,
    name ? null,
  }:
    if name == null
    then mkHost {inherit hosts name;}
    else if hosts != {}
    then head (attrValues hosts)
    else throw "No hosts available";

  mkAccess = host: let
    raw = host.access or {};
    remote = raw.remote or {};
    ssh = remote.ssh or {};
    tailscale = remote.tailscale or {};
    caddy = remote.caddy or {};
  in
    raw
    // {
      remote = {
        ssh = ssh // {
          enable = ssh.enable or (raw.ssh or null) != null;
          keyOnly = ssh.keyOnly or true;
        };
        tailscale = tailscale // {
          enable = tailscale.enable or (builtins.elem "vpn" (host.functionalities or []));
        };
        caddy = caddy // {enable = caddy.enable or false;};
      };
      tailscale = tailscale // {
        enable = tailscale.enable or (builtins.elem "vpn" (host.functionalities or []));
      };
    };

  mkNetwork = host: let
    network = host.network or {};
  in {
    backend = network.backend or "networkmanager";
  };

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
    enrichedAccess = mkAccess host;
    enrichedNetwork = mkNetwork host;
    enrichment = {
      inherit name;
      inherit (host.paths) dots;
      system = host.specs.platform or "x86_64-linux";
      users = enrichedUser;
      interface = enrichedUI;
      localization = enrichedLocale;
      hardware = enrichedHardware;
      access = enrichedAccess;
      network = enrichedNetwork;
    };
  in
    host // enrichment;
in
  __exports.internal // {__rootAliases = __exports.external;}
