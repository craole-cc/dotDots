{_, ...}: let
  __exports = {
    internal = {inherit mkHost mkCore hostOrDefault;};
    external = {mkCoreSchema = mkCore;};
  };

  inherit (_.attrsets.access) attrNames attrValues;
  inherit (_.attrsets.aggregation) recursiveUpdate;
  inherit (_.lists.access) head;
  inherit (_.lists.predicates) any elem;
  inherit (_.schema.construction) mkUI mkHome mkLocale mkHardware;
  inherit (_.strings.construction) generateHexId;
  inherit (_.filesystem.construction) mkTree;

  mkHost = {
    hosts,
    name ? null,
  }:
    hosts.${
      name
    } or (throw "Host '${name}' not found. Available hosts: ${
      toString (attrNames hosts)
    }");

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

    ssh = let
      ssh = remote.ssh or {};
    in
      ssh
      // {
        enable = ssh.enable or (raw.ssh or null) != null;
        keyOnly = ssh.keyOnly or true;
      };

    tailscale = let
      tailscale = remote.tailscale or {};
      enable = tailscale.enable or (elem "vpn" (host.functionalities or []));
    in
      tailscale // {inherit enable;};

    caddy = let
      caddy = remote.caddy or {};
      enable = caddy.enable or (elem "webDev" (host.functionalities or []));
    in
      caddy // {inherit enable;};
  in
    raw
    // {
      remote = {inherit caddy ssh tailscale;};
      inherit tailscale;
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
  mkDevelopmentCapability = {
    host,
    interactiveUsers,
  }: let
    explicit = (host.capabilities or {}).development or null;
    hardened = host.hardened or false;
    hostDeclared = elem "development" (host.functionalities or []);
    userDeclared = any (user: elem "development" (user.capabilities or [])) (
      attrValues interactiveUsers
    );
  in
    if explicit != null
    then explicit
    else if hardened
    then false
    else hostDeclared || userDeclared || true;

  mkStorage = host: let
    raw = host.storage or {};
  in {
    filesystemsRequired =
      raw.filesystemsRequired or (
        host.class or "nixos" == "nixos"
      );
  };

  /**
  Enrich a single host with user data, interface normalization, and metadata.
  */
  mkCore = {
    name,
    host,
    users,
    roots ? {},
    stems ? {},
    exclusions ? {},
    ...
  }: let
    derived = {
      inherit host name;
      stems = recursiveUpdate stems (host.paths.stems or {});
      roots = recursiveUpdate roots (host.paths.roots or {});
      paths = mkTree {inherit (derived) roots stems;};

      exclusions = recursiveUpdate exclusions (host.exclusions or {});

      users = mkHome {
        inherit host users;
        inherit (derived) roots stems;
      };

      user = derived.users.primary;
    };

    defined = with derived; {
      inherit name paths users exlusions;

      id =
        if (host.id or null) != null
        then host.id
        else generateHexId {inherit name;};

      interface = mkUI {inherit host user;};
      localization = mkLocale {inherit host user;};

      home = host.paths.roots.repo;
      system = host.system or (host.specs.platform or null);

      hardware = mkHardware {inherit host;};
      access = mkAccess host;
      network = mkNetwork host;

      capabilities.development = mkDevelopmentCapability {
        inherit host;
        interactiveUsers = users.interactive;
      };

      storage = mkStorage host;
    };
  in
    recursiveUpdate host defined;
in
  __exports.internal // {__rootAliases = __exports.external;}
