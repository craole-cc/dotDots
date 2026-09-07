{_, ...}: let
  __exports = {
    internal = {inherit mkHost mkCore hostOrDefault;};
    external = {
      mkCoreSchema = mkCore;
    };
  };

  inherit (_.attrsets.access) attrNames attrValues;
  inherit (_.attrsets.aggregation) recursiveUpdate;
  inherit (_.lists.access) head;
  inherit (_.lists.predicates) any elem;
  inherit (_.schema.hardware) mkHardware;
  inherit (_.schema.home) mkHome;
  inherit (_.schema.locale) mkLocale;
  inherit (_.schema.ui) mkUI;
  inherit (_.strings.construction) generateHexId;
  inherit (_.filesystem.construction) mkTree;

  mkHost = {
    hosts,
    name ? null,
  }:
    hosts.${name} or (throw "Host '${name}' not found. Available hosts: ${toString (attrNames hosts)}");

  hostOrDefault = {
    hosts,
    name ? null,
  }:
    if name != null && hosts ? ${name}
    then hosts.${name}
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
    raw = host.devices.storage or {};
  in {
    filesystemsRequired = raw.filesystemsRequired or (host.class or "nixos" == "nixos");
  };

  /**
  Enrich a single host with user data, shell policy, interface normalization,
  and metadata.
  */
  mkCore = {
    name,
    host,
    users,
    shells ? {},
    roots ? {},
    stems ? {},
    exclusions ? {},
    ...
  }: let
    userProfiles = users;

    derived = {
      inherit host name;
      stems = recursiveUpdate stems (host.paths.stems or {});
      roots = recursiveUpdate roots (host.paths.roots or {});
      paths = mkTree {inherit (derived) roots stems;};
      shells = recursiveUpdate shells (host.shells or {});

      exclusions = recursiveUpdate exclusions (host.exclusions or {});

      users = mkHome {
        inherit host;
        users = userProfiles;
        inherit (derived) roots stems;
      };

      user = derived.users.primary;
    };

    defined = with derived; {
      inherit
        name
        paths
        shells
        users
        exclusions
        ;

      id =
        if (host.id or null) != null
        then host.id
        else generateHexId {inherit name;};

      interface = mkUI {inherit host user;};
      localization = mkLocale {inherit host user;};

      home = let
        src = host.paths.roots.repo;
      in
        if src != null
        then src
        else throw "Host: '${name}' must explicitly set `paths.roots.repo` to the path of the repo.";

      system = let
        sys = host.system or (host.specs.platform or null);
      in
        if sys != null
        then sys
        else throw "Host '${name}' must explicitly set 'system' or 'specs.platform'.";

      hardware = mkHardware {inherit host;};
      access = mkAccess host;
      network = mkNetwork host;

      capabilities.development = mkDevelopmentCapability {
        inherit host;
        interactiveUsers = derived.users.interactive;
      };

      storage = mkStorage host;
    };
  in
    recursiveUpdate host defined;
in
  __exports.internal // {__rootAliases = __exports.external;}
