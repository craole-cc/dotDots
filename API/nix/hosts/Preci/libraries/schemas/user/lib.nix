{
  lib,
  lix,
  default,
  mkMergedList,
  mkMergedAttrs,
  deriveApplications,
  resolveNames,
  expandNames,
  ...
}: let
  inherit (lib.attrsets) attrNames mapAttrs optionalAttrs recursiveUpdate;
  inherit (lib.lists) any concatMap elemAt filter foldl' head length optionals reverseList tail unique;
  inherit (lix.trivial) isNotEmpty pathExists;
  inherit (lix.debug) requireNonEmpty requireThat;

  deriveUserCapabilities = args: let
    names = attrNames args;
    unknown = filter (name: !(default.capabilities ? ${name})) names;
    context = "deriveUserCapabilities";
  in
    assert requireThat {
      inherit context;
      condition = unknown == [];
      message = "unknown capabilities: ${toString unknown}";
    }; args;

  mkUserCapabilities = {
    declared ? {},
    requested ? {},
  }: let
    requested' = deriveUserCapabilities requested;
  in {
    inherit declared;
    requested = requested';
    merged =
      recursiveUpdate
      declared
      (
        mapAttrs
        (
          name: value:
            recursiveUpdate
            default.capabilities.${name}
            value
        )
        requested'
      );
  };

  deriveUser = args: let
    defined =
      recursiveUpdate
      default
      args;
    name = defined.name or "<unnamed principal>";
    context = "mkUser \"${toString name}\"";
    applications = deriveApplications {inherit default defined;};
    set = defined // {inherit applications;};
    isSet = path: requireNonEmpty {inherit context path set;};
  in
    assert (isSet ["name"]);
    assert (isSet ["role"]);
    assert (isSet ["hashedPassword"]);
    #> Return the validated principal
      set;

  mkUser = {
    args,
    registry ? null,
  }: let
    derived = deriveUser args;
    context = "mkUser \"${toString derived.name}\"";
    requested = deriveUser (
      recursiveUpdate (
        optionalAttrs (isNotEmpty registry) (
          let
            directory = registry + "/${derived.name}";
            file = registry + "/${derived.name}.nix";
          in
            optionalAttrs (pathExists file) (import file)
            // optionalAttrs (pathExists directory) (import directory)
        )
      )
      args
    );

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
          requested.name or null;
      };
      role = mkValue {
        declared = derived.role;
        requested =
          requested.role or null;
      };
      description = mkValue {
        declared = "${toString derived.name} (${toString derived.role})";
        requested =
          requested.description or null;
      };
      enable = mkValue {
        declared = derived.enable;
        requested =
          requested.enable or null;
      };
      autoLogin = mkValue {
        declared = derived.autoLogin;
        requested =
          requested.autoLogin or null;
      };
      capabilities = mkUserCapabilities {
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

  mkUsers = {
    context,
    args,
    registry ? null,
  }: let
    # principals = map mkUser args;
    principals =
      map
      (args: mkUser {inherit args registry;})
      args;
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
      desktops = unique (
        concatMap
        (principal: principal.interface.desktops or [])
        principals
      );
      fonts = {
        clock = unique (
          concatMap
          (principal: principal.interface.fonts.clock or [])
          principals
        );
        emoji = unique (
          concatMap
          (principal: principal.interface.fonts.emoji or [])
          principals
        );
        material = unique (
          concatMap
          (principal: principal.interface.fonts.material or [])
          principals
        );
        monospace = unique (
          concatMap
          (principal: principal.interface.fonts.monospace or [])
          principals
        );
        sans = unique (
          concatMap
          (principal: principal.interface.fonts.sans or [])
          principals
        );
        serif = unique (
          concatMap
          (principal: principal.interface.fonts.serif or [])
          principals
        );
      };
      themes =
        foldl'
        recursiveUpdate
        {}
        (
          reverseList (
            map
            (principal: principal.interface.themes or {})
            principals
          )
        );
      cursors =
        foldl'
        recursiveUpdate
        {}
        (
          reverseList (
            map
            (principal: principal.interface.cursors or {})
            principals
          )
        );
      keyboard =
        foldl'
        recursiveUpdate
        {}
        (
          reverseList (
            map
            (principal: principal.interface.keyboard or {})
            principals
          )
        );
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
    deriveUserCapabilities
    deriveUser
    mkUserCapabilities
    mkUsers
    mkUser
    ;
}
