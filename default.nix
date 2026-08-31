{...} @ args: let
  cleanArgs = removeAttrs args ["schema" "host"];

  # 1. Force bootstrap args to use the local workspace root instead of store paths
  bootArgs =
    cleanArgs
    // {
      src = ./.;
      self = ./.;
    };

  boot = (import ./Libraries/nix bootArgs).libraries.default;
  inherit (boot.filesystem.traversal) importAttrs;
  inherit (boot.schema.construction) mkSchema;

  api = (importAttrs ./API/nix).value;
  schema = mkSchema {inherit api args;};
  host = schema.hosts.default;

  # Ensure resolvedFlake defaults to an empty set if null
  resolvedFlake = cleanArgs.flake or (cleanArgs.self or {});
  safeFlake =
    if resolvedFlake == null
    then {}
    else resolvedFlake;
in
  import ./Libraries/nix (bootArgs
    // {
      inherit schema host;
      src = host.paths.src;
      self = host.paths.src;
      flake =
        safeFlake
        // {
          home = host.paths.src;
        };
    })
