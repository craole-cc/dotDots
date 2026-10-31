{_, ...}: let
  __exports = {
    internal = {inherit mkHost mkCore mkAi hostOrDefault;};
    external = {
      mkCoreSchema = mkCore;
    };
  };

  inherit (_.attrsets.access) attrNames attrValues;
  inherit (_.attrsets.construction) optionalAttrs;
  inherit (_.attrsets.aggregation) recursiveUpdate;
  inherit (_.lists.access) head;
  inherit (_.lists.construction) optional toList;
  inherit (_.lists.transformation) unique;
  inherit (_.types.predicates) isAttrs;
  inherit (_.lists.predicates) any elem;
  inherit (_.schema.hardware) mkHardware normalizeCpu;
  inherit (_.schema.home) mkHome;
  inherit (_.schema.locale) mkLocale;
  inherit (_.schema.packages) normalize;
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

  mkAi = host: let
    ai = host.ai or {};
    ollama = ai.ollama or {};
    disableDefaults = ollama.disableDefaults or false;
    cores = (normalizeCpu {inherit host;}).cores or 0;
    role = name: fallback: let
      declared = ollama.models.${name} or [];
      models = unique (
        toList (if isAttrs declared then declared.models or [] else declared)
        ++ optional (!disableDefaults) fallback
      );
    in {
      inherit models;
      active = if models == [] then null else head models;
    };
  in
    ai // {
      ollama = ollama // {
        inherit disableDefaults;
        models = (ollama.models or {}) // {
          autocomplete = role "autocomplete" (
            if cores >= 4 then "qwen2.5-coder:1.5b-base-q4_K_M" else "qwen2.5-coder:0.5b-base-q4_K_M"
          );
          chat = role "chat" (
            if cores >= 4 then "qwen3:4b-instruct" else "qwen3:0.6b"
          );
        };
      };
    };

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

    guacamole = let
      guacamole = remote.guacamole or {};
      enable = guacamole.enable or false;
    in
      guacamole // {inherit enable;};

    caddy = let
      caddy = remote.caddy or {};
      enable = caddy.enable or (elem "webDev" (host.functionalities or []));
    in
      caddy // {inherit enable;};
  in
    raw
    // {
      remote = {inherit caddy guacamole ssh tailscale;};
      inherit tailscale;
    };

  mkNetwork = host: let
    network = host.network or {};
  in {
    backend = network.backend or "networkmanager";
  };

  #> A capability is declared either as a bare name in a list (`["development"]`)
  #> or as a key in a structured capability map (`{development = {...};}`). Both
  #> shapes are in use - `user.capabilities` is a structured map while
  #> `host.functionalities` is a list of names - so membership has to be tested
  #> for both rather than assuming one.
  hasCapability = declared: name:
    (
      declared
      != null
      && builtins.isAttrs declared
      && declared ? ${name}
    )
    #> `elem` throws on a non-list, so the list case has to be tested second:
    #> the structured-map check above must never be preceded by it.
    || (
      declared
      != null
      && builtins.isList declared
      && elem name declared
    );

  #> `roots.repo` and `roots.src` are aliases for the same thing. Both spellings
  #> are in active use across host data - `QBX`/`TheOracle` declare `repo`,
  #> `Victus` declares `src` - so the repo root resolves through either, with
  #> `repo` winning when both are present.
  repoRoot = roots: (roots.repo or (roots.src or null));

  mkDevelopmentCapability = {
    host,
    interactiveUsers,
  }: let
    explicit = (host.capabilities or {}).development or null;
    hardened = host.hardened or false;
    hostDeclared = hasCapability (host.functionalities or []) "development";
    userDeclared = any (user: hasCapability (user.capabilities or []) "development") (
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
  Enrich a single host with user data, shell policy, interface normalisation,
  settings normalisation, and metadata.
  */
  mkCore = {
    name,
    host,
    users,
    settings ? {},
    shells ? {},
    roots ? {},
    stems ? {},
    exclusions ? {},
    ...
  }: let
    userProfiles = users;
    normalized = normalize {
      record = host;
      protocol = defined.interface.displayProtocol;
    };
    resolvedPackages = recursiveUpdate (settings.pkg or settings.packages or {}) normalized.packages;

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

    # `with derived` is intentionally avoided here. Lexically-bound mkCore
    # arguments such as `shells`, `users`, and `exclusions` take precedence
    # over names introduced by `with`, which previously caused the raw/global
    # values to be inherited instead of their host-enriched derivatives.
    defined = {
      inherit
        (derived)
        name
        paths
        shells
        users
        exclusions
        ;

      # mkSchema normalises global + host package/library settings before
      # calling mkCore. Keep the canonical settings tree and project the
      # normalized aliases back onto the host so existing consumers of
      # host.packages / host.libraries see the merged schema values rather
      # than only the sparse per-host declarations.
      settings =
        settings
        // {pkg = resolvedPackages;}
        // optionalAttrs (settings ? packages) {packages = resolvedPackages;};
      packages = resolvedPackages;
      libraries = settings.lib or settings.libraries or (host.libraries or {});

      id =
        if (host.id or null) != null
        then host.id
        else generateHexId {inherit name;};

      defaults.interface = host.defaults.interface or (host.interface or {});
      theme = _.schema.theme.mkTheme {inherit host;};

      interface = mkUI {
        inherit host;
        inherit (derived) user;
      };
      locale = mkLocale {
        inherit host;
        inherit (derived) user;
      };

      home = let
        src = repoRoot (host.paths.roots or {});
      in
        if src != null
        then src
        else throw "Host: '${name}' must explicitly set `paths.roots.repo` (or its alias `paths.roots.src`) to the path of the repo.";

      system = let
        sys = host.system or (host.specs.platform or null);
      in
        if sys != null
        then sys
        else throw "Host '${name}' must explicitly set 'system' or 'specs.platform'.";

      hardware = mkHardware {inherit host;};
      ai = mkAi host;
      access = mkAccess host;
      network = mkNetwork host;

      capabilities.development = mkDevelopmentCapability {
        inherit host;
        interactiveUsers = derived.users.interactive;
      };

      storage = mkStorage host;
    };
  in
    recursiveUpdate normalized defined;
in
  __exports.internal // {__rootAliases = __exports.external;}
