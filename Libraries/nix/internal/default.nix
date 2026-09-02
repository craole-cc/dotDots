{
  settings,
  lib,
  names,
  paths,
  ...
} @ args: let
  inherit (lib.fixedPoints) makeExtensible;
  inherit (lib.attrsets) recursiveUpdate;
  inherit (settings) allowAliases allowTests exclusions;

  handleCollisions = import ./collisions.nix {
    inherit lib;
    inherit (settings) collisionStrategy;
  };

  assembleLibrary = library:
    (
      import ./assemble.nix
      {inherit handleCollisions lib library paths allowAliases;}
    )
    // {seed = extra: import ./. (recursiveUpdate args extra);};

  default = assembleLibrary (
    makeExtensible (self: let
      safe = handleCollisions {
        msg = "Custom library has collisions with nixpkgs lib";
        overrides = self;
      };

      env = let
        extraArgs = {
          inherit safe;
          _ = self;
          self = self;
          name = names.lib;
          _defaults = args;
          _default = args;
          projectPath = args.paths.repo.src.store;
          projectHome = args.paths.repo.src.local;
        };
      in
        args // extraArgs;

      scan = import ./scan.nix {
        inherit env paths lib allowTests exclusions;
      };

      resolved = scan paths.repo.lib.default.store [];
    in
      resolved.modules // {__rootAliases = resolved.rootAliases;})
  );

  named = {${names.lib} = default;};
in
  default.sources.packages.mkAll (
    args
    // {libraries = {inherit default;} // named;}
    // named
  )
