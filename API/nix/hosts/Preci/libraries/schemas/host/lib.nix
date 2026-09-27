{
  lib,
  lix,
  default,
  ...
}: let
  inherit (lib.attrsets) recursiveUpdate;
  inherit (lib.strings) hashString isString match substring toJSON;
  inherit (lix.trivial) isNotEmpty;
  inherit (lix.debug) requireNonEmpty requireThat;

  mkHost = {
    args,
    registry ? null,
  }: let
    derived = deriveHost args;
    context = "mkHost \"${toString derived.name}\"";

    defined = let
      principals = mkUsers {
        inherit context registry;
        args = derived.principals or [];
      };

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

  deriveHost = args: let
    defined =
      recursiveUpdate
      default
      args;
    functionalities = deriveFunctionalities {inherit default defined;};
    applications = deriveApplications {inherit default defined;};
    set = defined // {inherit applications functionalities;};
    name = defined.name or "<unnamed host>";
    context = "mkHost \"${toString name}\"";

    isSet = path: requireNonEmpty {inherit context path set;};
  in
    assert (requireThat {
      inherit context;
      condition =
        (set.id == null)
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
in {inherit deriveHost mkHost;}
