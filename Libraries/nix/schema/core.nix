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

  # Development capability precedence, strongest to weakest:
  # 1. Explicit host.capabilities.development = false disables it absolutely.
  # 2. Explicit host.capabilities.development = true enables it absolutely.
  # 3. host.hardened = true disables inferred development capability.
  # 4. host.functionalities containing "development" enables it.
  # 5. Any enabled interactive user's capabilities containing "development" enables it.
  # 6. Otherwise non-hardened hosts default to true.
  mkDevelopmentCapability = {host, interactiveUsers}: let
    explicit = (host.capabilities or {}).development or null;
    hardened = host.hardened or false;
    hostDeclared = builtins.elem "development" (host.functionalities or []);
    userDeclared = builtins.any (u: builtins.elem "development" (u.capabilities or [])) (attrValues interactiveUsers);
  in
    if explicit != null
    then explicit
    else if hardened
    then false
    else hostDeclared || userDeclared || true;

  mkStorage = host: let
    raw = host.storage or {};
  in {
    filesystemsRequired = raw.filesystemsRequired or (host.class or "nixos" == "nixos");
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
    enrichedCapabilities = {
      development = mkDevelopmentCapability {
        inherit host;
        interactiveUsers = enrichedUser.data.interactive;
      };
    };
    enrichedStorage = mkStorage host;
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
      capabilities = enrichedCapabilities;
      storage = enrichedStorage;
    };
  in
    host // enrichment;
in
  __exports.internal // {__rootAliases = __exports.external;}
