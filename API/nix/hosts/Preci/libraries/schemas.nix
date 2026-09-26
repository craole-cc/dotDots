{
  lib,
  trivial,
  debug,
  schema,
  ...
}: let
  inherit (lib.attrsets) attrNames mapAttrs recursiveUpdate;
  inherit (lib.lists) any concatMap elemAt filter foldl' head length optionals reverseList tail unique;
  inherit (lib.strings) hashString isString match substring toJSON;
  inherit (trivial) isNotEmpty;
  inherit (debug) requireNonEmpty requireThat;

  mkMergedList = {
    declared,
    requested,
  }: {
    inherit declared requested;
    merged = unique (requested ++ declared);
  };

  mkMergedAttrs = {
    declared,
    requested,
  }: {
    inherit declared requested;
    #> Principal order is significant: earlier principals have priority.
    merged =
      foldl'
      recursiveUpdate
      declared
      (reverseList requested);
  };

  deriveCapabilities = args: let
    names = attrNames args;
    unknown = filter (name: !(schema.user.capabilities ? ${name})) names;
    context = "deriveCapabilities";
  in
    assert requireThat {
      inherit context;
      condition = unknown == [];
      message = "unknown capabilities: ${toString unknown}";
    }; args;

  mkCapabilities = {
    declared ? {},
    requested ? {},
  }: let
    requested' = deriveCapabilities requested;
  in {
    inherit declared;
    requested = requested';
    merged =
      recursiveUpdate
      declared
      (mapAttrs
        (
          name: value:
            recursiveUpdate schema.user.capabilities.${name} value
        )
        requested');
  };

  mkHost = args: let
    derived = deriveHost args;
    context = "mkHost \"${toString derived.name}\"";

    defined = let
      principals =
        mkHostUsers context (derived.principals or []);

      desktops = mkMergedList {
        declared = derived.interface.desktops;
        requested = principals.interface.desktops;
      };

      fonts = {
        clock = mkMergedList {
          declared = derived.interface.fonts.clock;
          requested = principals.interface.fonts.clock;
        };
        emoji = mkMergedList {
          declared = derived.interface.fonts.emoji;
          requested = principals.interface.fonts.emoji;
        };
        material = mkMergedList {
          declared = derived.interface.fonts.material;
          requested = principals.interface.fonts.material;
        };
        monospace = mkMergedList {
          declared = derived.interface.fonts.monospace;
          requested = principals.interface.fonts.monospace;
        };
        sans = mkMergedList {
          declared = derived.interface.fonts.sans;
          requested = principals.interface.fonts.sans;
        };
        serif = mkMergedList {
          declared = derived.interface.fonts.serif;
          requested = principals.interface.fonts.serif;
        };
      };

      themes = mkMergedAttrs {
        declared = derived.interface.themes;
        requested = principals.interface.themes;
      };

      keyboard = mkMergedAttrs {
        declared = derived.interface.keyboard;
        requested = principals.interface.keyboard;
      };

      cursors = mkMergedAttrs {
        declared = derived.interface.cursors;
        requested = principals.interface.cursors;
      };
    in {
      inherit derived principals;

      id =
        if isNotEmpty derived.id
        then derived.id
        else
          substring 0 8 (hashString "sha256" (toJSON {
            inherit (derived) name class description stateVersion;
          }));

      interface = {
        desktops = desktops.merged;
        fonts = {
          clock = fonts.clock.merged;
          emoji = fonts.emoji.merged;
          material = fonts.material.merged;
          monospace = fonts.monospace.merged;
          sans = fonts.sans.merged;
          serif = fonts.serif.merged;
        };
        themes = themes.merged;
        cursors = cursors.merged;
        keyboard = keyboard.merged;
      };

      meta = {
        interface = {
          inherit desktops fonts themes cursors keyboard;
        };
      };

      paths = derived.paths;
    };
  in
    recursiveUpdate derived defined;

  deriveFunctionalities = args: let
    names = unique args;
    unknown =
      filter
      (name: !(schema.host.functionalities ? ${name}))
      names;
    context = "deriveFunctionalities";
  in
    assert requireThat {
      inherit context;
      condition = unknown == [];
      message = "unknown functionalities: ${toString unknown}";
    }; names;

  deriveHost = args: let
    raw =
      recursiveUpdate
      schema.host.defaults
      args;
    functionalities = deriveFunctionalities raw.functionalities;
    set = raw // {inherit functionalities;};
    name = raw.name or "<unnamed host>";
    context = "mkHost \"${toString name}\"";

    isSet = path: requireNonEmpty {inherit context path set;};
  in
    assert (requireThat {
      inherit context;
      condition =
        set.id
        == null
        || (
          (isString set.id)
          && (isNotEmpty (match "^([0-9a-fA-F]{8})$" set.id))
        );
      message = "id must be null or an 8-character hex string, got '${toString set.id}'";
    });
    assert (isSet ["paths" "roots" "src"]);
    assert (isSet ["paths" "roots" "run"]);
    assert (isSet ["stateVersion"]);
    assert (isSet ["system"]);
    assert (isSet ["name"]);
    #> Return the validated host
      set;
  derivePrincipal = args: let
    raw =
      recursiveUpdate
      schema.user.defaults
      args;
    name = raw.name or "<unnamed principal>";
    context = "mkPrincipal \"${toString name}\"";

    applications = deriveApplications raw.applications;
    set = raw // {inherit applications;};
    isSet = path: requireNonEmpty {inherit context path set;};
  in
    assert (isSet ["name"]);
    assert (isSet ["role"]);
    assert (isSet ["hashedPassword"]);
    #> Return the validated principal
      set;

  deriveApplications = args: let
    names = attrNames args;
    unknown =
      filter
      (name: !(schema.user.applications ? ${name}))
      names;
    context = "deriveApplications";
  in
    assert requireThat {
      inherit context;
      condition = unknown == [];
      message = "unknown application roles: ${toString unknown}";
    }; args;
  mkPrincipal = args: let
    derived = derivePrincipal args;
    context = "mkPrincipal \"${toString derived.name}\"";
    requested = args;

    mkValue = {
      declared,
      requested ? null,
    }: {
      inherit declared requested;
      merged =
        if requested == null
        then declared
        else requested;
    };

    defined = let
      name = mkValue {
        declared = derived.name;
        requested =
          if requested ? name
          then requested.name
          else null;
      };
      role = mkValue {
        declared = derived.role;
        requested =
          if requested ? role
          then requested.role
          else null;
      };
      description = mkValue {
        declared = "${toString derived.name} (${toString derived.role})";
        requested =
          if requested ? description
          then requested.description
          else null;
      };
      enable = mkValue {
        declared = derived.enable;
        requested =
          if requested ? enable
          then requested.enable
          else null;
      };
      autoLogin = mkValue {
        declared = derived.autoLogin;
        requested =
          if requested ? autoLogin
          then requested.autoLogin
          else null;
      };
      capabilities = mkCapabilities {
        requested = requested.capabilities or {};
      };

      git = mkMergedAttrs {
        declared = derived.git;
        requested = requested.git or {};
      };

      applications = mkMergedAttrs {
        declared = derived.applications;
        requested = requested.applications or {};
      };

      localization = mkMergedAttrs {
        declared = derived.localization;
        requested = requested.localization or {};
      };
      identities = mkMergedList {
        declared = derived.identities;
        requested = requested.identities or [];
      };

      desktops = mkMergedList {
        declared = derived.interface.desktops;
        requested = requested.interface.desktops or [];
      };

      fonts = {
        clock = mkMergedList {
          declared = derived.interface.fonts.clock;
          requested = requested.interface.fonts.clock or [];
        };
        emoji = mkMergedList {
          declared = derived.interface.fonts.emoji;
          requested = requested.interface.fonts.emoji or [];
        };
        material = mkMergedList {
          declared = derived.interface.fonts.material;
          requested = requested.interface.fonts.material or [];
        };
        monospace = mkMergedList {
          declared = derived.interface.fonts.monospace;
          requested = requested.interface.fonts.monospace or [];
        };
        sans = mkMergedList {
          declared = derived.interface.fonts.sans;
          requested = requested.interface.fonts.sans or [];
        };
        serif = mkMergedList {
          declared = derived.interface.fonts.serif;
          requested = requested.interface.fonts.serif or [];
        };
      };

      themes = mkMergedAttrs {
        declared = derived.interface.themes;
        requested = requested.interface.themes or {};
      };

      keyboard = mkMergedAttrs {
        declared = derived.interface.keyboard;
        requested = requested.interface.keyboard or {};
      };

      cursors = mkMergedAttrs {
        declared = derived.interface.cursors;
        requested = requested.interface.cursors or {};
      };

      paths = let
        requestedPaths = requested.paths or {};
        requestedRoots = requestedPaths.roots or {};
        declared = {
          roots.home = "/home/${toString derived.name}";
          stems = {};
        };
      in
        assert requireThat {
          inherit context;
          condition = !(requestedRoots ? src) && !(requestedRoots ? run);
          message = "paths.roots.src and paths.roots.run are reserved for the host";
        };
          mkMergedAttrs {
            inherit declared;
            requested = requestedPaths;
          };

      packages = {
        shells = mkMergedList {
          declared = derived.packages.shells;
          requested = requested.packages.shells or [];
        };
        common = mkMergedList {
          declared = derived.packages.common;
          requested = requested.packages.common or [];
        };
        launchers = mkMergedList {
          declared = derived.packages.launchers;
          requested = requested.packages.launchers or [];
        };
      };
    in {
      name = name.merged;
      role = role.merged;
      description = description.merged;
      enable = enable.merged;
      autoLogin = autoLogin.merged;
      capabilities = capabilities.merged;
      git = git.merged;
      applications = applications.merged;
      identities = identities.merged;
      localization = localization.merged;

      interface = {
        desktops = desktops.merged;
        fonts = {
          clock = fonts.clock.merged;
          emoji = fonts.emoji.merged;
          material = fonts.material.merged;
          monospace = fonts.monospace.merged;
          sans = fonts.sans.merged;
          serif = fonts.serif.merged;
        };
        themes = themes.merged;
        cursors = cursors.merged;
        keyboard = keyboard.merged;
      };

      inherit paths;

      packages = {
        shells = packages.shells.merged;
        common = packages.common.merged;
        launchers = packages.launchers.merged;
      };

      meta = {
        inherit name role description enable autoLogin capabilities git applications identities localization;
        interface = {
          inherit desktops fonts themes cursors keyboard;
        };
        inherit paths packages;
      };
    };
  in
    recursiveUpdate derived defined;
  mkHostUsers = context: args: let
    principals = map mkPrincipal args;
    hasAdmin = any (principal: principal.role == "administrator") principals;
    total = length principals;
    primary = head principals;
    secondary =
      if total > 1
      then elemAt principals 1
      else null;
    tertiary =
      if total > 2
      then elemAt principals 2
      else null;
    others = optionals (total > 3) (tail (tail (tail principals)));
    names = map (user: user.name) principals;
    interface = {
      desktops = unique (concatMap (user: user.interface.desktops or []) principals);
      fonts = {
        clock = unique (concatMap (user: user.interface.fonts.clock or []) principals);
        emoji = unique (concatMap (user: user.interface.fonts.emoji or []) principals);
        material = unique (concatMap (user: user.interface.fonts.material or []) principals);
        monospace = unique (concatMap (user: user.interface.fonts.monospace or []) principals);
        sans = unique (concatMap (user: user.interface.fonts.sans or []) principals);
        serif = unique (concatMap (user: user.interface.fonts.serif or []) principals);
      };
      themes =
        foldl'
        recursiveUpdate
        {}
        (reverseList (map (user: user.interface.themes or {}) principals));
      cursors =
        foldl'
        recursiveUpdate
        {}
        (reverseList (map (user: user.interface.cursors or {}) principals));
      keyboard =
        foldl'
        recursiveUpdate
        {}
        (reverseList (map (user: user.interface.keyboard or {}) principals));
    };
    count = total;
  in
    assert requireThat {
      inherit context;
      message = "principals list must not be empty";
      condition = isNotEmpty principals;
    };
    assert requireThat {
      inherit context;
      message = "at least one principal must have role \"administrator\" (got: ${toString names})";
      condition = hasAdmin;
    }; {
      all = principals;
      inherit primary secondary tertiary others names count interface;
    };
in {
  inherit
    deriveApplications
    deriveCapabilities
    deriveFunctionalities
    deriveHost
    derivePrincipal
    mkCapabilities
    mkHost
    mkHostUsers
    mkPrincipal
    ;
}
