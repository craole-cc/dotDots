{
  api,
  config,
  host ? target,
  lib,
  names,
  target ? null,
  paths,
  ...
} @ args: let
  inherit (builtins) isAttrs isString;
  inherit (lib.fixedPoints) makeExtensible;
  inherit (lib.attrsets) recursiveUpdate;
  inherit (config) allowAliases allowTests exclusions;

  handleCollisions = import ./collisions.nix {
    inherit lib;
    inherit (config) collisionStrategy;
  };

  mkLibrary = extraArgs:
    import ./assemble.nix {
      inherit handleCollisions lib paths allowAliases;
      library = makeExtensible (
        self: let
          safe = handleCollisions {
            msg = "Custom library has collisions with nixpkgs lib";
            overrides = self;
          };

          env = let
            _defaults = args // extraArgs;
            name = names.lib;
            top = {_ = self;};
          in
            _defaults // top // {inherit _defaults safe self name;};

          scan = import ./scan.nix {
            inherit env paths lib allowTests exclusions;
          };

          result = scan paths.core.lib.nix.store [];
        in
          result.modules // {__rootAliases = result.rootAliases;}
      );
    };

  bootstrap = mkLibrary {};

  extraArgs = let
    inherit (bootstrap.schema.construction) mkSchema;

    base = mkSchema api;

    host' =
      if isString host
      then base.hosts.${host} or base.hosts.default
      else if isAttrs host
      then recursiveUpdate (base.hosts.${host.name or "default"} or base.hosts.default) host
      else base.hosts.default;

    user' = base.users.${host'.users.primary.name or ""} or base.users.default;
    schema =
      base
      // {
        hosts = base.hosts // {default = host';};
        users = base.users // {default = user';};
      };
  in
    args
    // {
      inherit schema;
      host = schema.hosts.default;
    };

  default = mkLibrary extraArgs;
  named = {${names.lib} = default;};
  libraries = {inherit default;} // named;
  inherit (default.sources.packages) mkAll;
in
  mkAll (extraArgs // {inherit libraries;} // named)
