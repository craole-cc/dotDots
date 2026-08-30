{
  api,
  config,
  flake ? null,
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

  mkLib = args:
    bootstrap.modules.construction.mkLib (args // {src = paths.core.src.store;});

  extraArgs = let
    inherit (bootstrap.attrsets.access) attrNamesHead;
    inherit (bootstrap.schema.construction) mkSchema;
    inherit (bootstrap.strings.access) getEnvOr;

    base = mkSchema args.api;
    targetName =
      if isString host
      then host
      else if isAttrs host
      then host.name or null
      else null;
    schemaHost =
      if targetName != null
      then base.hosts.${targetName} or {}
      else let
        name = getEnvOr "HOSTNAME" (attrNamesHead base.hosts);
      in
        base.hosts.${name} or {};
    resolvedHost =
      if isAttrs host
      then recursiveUpdate schemaHost host
      else schemaHost;
    user = let
      name = getEnvOr "USER" (resolvedHost.users.primary.name or "");
    in
      resolvedHost.users.all.${name} or null;
    schema =
      base
      // {
        hosts = base.hosts // {default = resolvedHost;};
        users = base.users // {default = user;};
      };
  in
    args
    // {
      inherit schema;
      host = resolvedHost;
      target = host;
      inherit mkLib;
    };

  inherit (default.sources.packages) mkAll;
  default = mkLibrary extraArgs;
  named = {
    ${args.names.lib} = default;
  };
  libraries =
    {
      inherit default;
    }
    // named;
in
  mkAll (
    extraArgs
    // {
      inherit libraries mkLib;
    }
    // named
  )
  // {inherit host target mkLib;}
