{
  _,
  lib,
  ...
}: let
  __doc = ''
    Build the host-specific core module list used during system evaluation.

    Produces the base module stack for a host by combining low-level hardware,
    networking, environment, services, programs, users, and home-manager glue.
    The result is returned as a module list suitable for `evalModules`.

    # Args:
    host: The enriched host definition.
    nixpkgs: The resolved nixpkgs source/configuration attrset.
    inputs: Canonically resolved flake inputs.
    modules: Resolved input-provided module sets.
    specialArgs: Extra arguments forwarded into module evaluation.

    # Returns:
    A list of modules for the target host, including any host-local imports.
  '';

  __exports = {
    internal = {
      inherit mkModules;
      mkCore = mkModules;
    };
    external = {mkCoreModules = mkModules;};
  };

  inherit (lib) extend;
  inherit (_.modules.home.users) mkUsers;

  /**
  Build the host-specific core module list used during system evaluation.

  Produces the base module stack for a host by combining low-level hardware,
  networking, environment, services, programs, users, and home-manager glue.
  The result is returned as a module list suitable for `evalModules`.

  # Args:
    host: The enriched host definition.
    nixpkgs: The resolved nixpkgs source/configuration attrset.
    inputs: Canonically resolved flake inputs.
    modules: Resolved input-provided module sets.
    specialArgs: Extra arguments forwarded into module evaluation.

  # Returns:
    A list of modules for the target host, including any host-local imports.
  */
  mkModules = {
    host,
    nixpkgs,
    inputs,
    modules,
    specialArgs,
    tree,
  }: [
    {
      inherit nixpkgs;
      home-manager = {
        backupFileExtension = "BaC";
        overwriteBackup = true;
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs =
          specialArgs
          // {
            lib = extend (_self: _super: {
              hm = inputs.home-manager.lib.hm or {};
            });
          };
        users = mkUsers {
          inherit inputs host tree;
          modules = modules.home;
        };
      };
    }
  ];
in
  __exports.internal
  // {
    inherit __doc;
    _rootAliases = __exports.external;
  }
