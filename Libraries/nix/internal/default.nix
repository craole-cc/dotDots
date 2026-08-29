{
  api,
  config,
  flake ? null,
  lib,
  names,
  paths,
  ...
} @ args: let
  inherit (lib.fixedPoints) makeExtensible;
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

  extraArgs =
    args
    // {
      schema = let
        inherit (bootstrap.attrnames.access) attrNamesHead;
        inherit (bootstrap.schema.construction) mkSchema;
        inherit (bootstrap.strings.access) getEnvOr;

        base = mkSchema args.api;

        host = let
          name = getEnvOr "HOSTNAME" (attrNamesHead base.hosts);
        in
          base.hosts.${name} or null;

        user = let
          name = getEnvOr "USER" base.hosts.${host.name}.users.primary.name;
        in
          base.hosts.${host.name}.users.all.${name} or null;
      in
        base
        // {
          hosts = base.hosts // {default = host;};
          users = base.users // {default = user;};
        };
    };

  inherit (default.sources.packages) mkAll;
  default = mkLibrary extraArgs;
  libraries = {
    inherit default;
    ${args.names.lib} = default;
  };
in
  mkAll (extraArgs // {inherit libraries;})
