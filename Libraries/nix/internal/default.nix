{
  api,
  collisionStrategy,
  exclusions,
  flake ? null,
  lib,
  names,
  paths,
  allowAliases,
  allowTests,
  ...
} @ args: let
  inherit (lib.fixedPoints) makeExtensible;

  default = let
    handleCollisions =
      import ./collisions.nix
      {inherit lib collisionStrategy;};

    library = makeExtensible (
      self: let
        safe = handleCollisions {
          msg = "Custom library has collisions with nixpkgs lib";
          overrides = self;
        };

        env = let
          extraArgs = {
            inherit safe self;
            _defaults = args;
            name = names.lib;
            _ = self;
          };
        in
          args // extraArgs;

        scan = import ./scan.nix {
          inherit env exclusions paths lib allowTests;
        };

        result = scan paths.core.lib.nix.store [];
      in
        result.modules // {__rootAliases = result.rootAliases;}
    );
  in
    import ./assemble.nix {
      inherit allowAliases library handleCollisions lib paths;
    };

  inherit (default.strings.access) getEnvOr;
  inherit (default.schema.construction) mkSchema;
  inherit (builtins) head attrNames;
  schema = mkSchema api;

  host = let
    name =
      getEnvOr "HOSTNAME"
      (head (attrNames api.hosts));
  in
    api.hosts.${name} or null;

  user = let
    name =
      getEnvOr "USER"
      schema.hosts.${host.name}.users.primary.name;
  in
    schema.hosts.${host.name}.users.all.${name} or null;
in
  args
  // {
    inherit schema;
    current = {inherit host user;};
    flake =
      args.flake
      // {
        name = args.flake.name or args.names.src;
        path = args.flake.path or args.paths.core.src.store;
        home = args.flake.home or (args.paths.core.src.local or null);
      };
    libraries = {
      inherit default;
      ${names.lib} = default;
    };
  }
