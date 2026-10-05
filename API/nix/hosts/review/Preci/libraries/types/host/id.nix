{lix, ...}: let
  inherit (lix.strings) hashString isString match substring toJSON;
  inherit (lix.trivial) isNotEmpty;
  inherit (lix.debug) requireThat;

  default = null;

  resolve = {
    id ? args.id or null,
    name ? args.name or null,
    class ? args.class or null,
    description ? args.description or null,
    stateVersion ? args.stateVersion or null,
    context ? "resolve host id (host \"${toString name}\")",
    ...
  } @ args:
    assert requireThat {
      inherit context;
      condition =
        (id == null)
        || (
          (isString id)
          && (isNotEmpty (match "^([0-9a-fA-F]{8})$" id))
        );
      message = "id must be null or an 8-character hex string, got '${toString id}'";
    };
      if isNotEmpty id
      then id
      else
        substring 0 8 (hashString "sha256" (toJSON {
          inherit name class description stateVersion;
        }));
in {inherit default resolve;}
