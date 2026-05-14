{ _, lib, ... }:
let
  __doc = ''
    Produce the complete Home Manager option block for the current host.

    Configures Home Manager to reuse the system package set, forward shared
    special arguments, and generate per-user configurations through the
    home user builder.

    # Args:
    host: The current host definition.
    specialArgs: Arguments forwarded into Home Manager modules.
    inputs: Canonically resolved flake inputs.
    modules: Resolved Home Manager module set.
    tree: Repository tree metadata used by downstream user builders.

    # Returns:
    A module fragment defining the `home-manager` configuration block.
  '';

  __exports = {
    internal = {
      inherit mkModules;
      mkHome = mkModules;
    };
    external = {
      mkHomeModules = mkModules;
    };
  };

  inherit (_.modules.home.users) mkUsers;
  inherit (lib) extend;

  /**
    Produce the complete Home Manager option block for the current host.

    Configures Home Manager to reuse the system package set, forward shared
    special arguments, and generate per-user configurations through the
    home user builder.

    # Args:
      host: The current host definition.
      specialArgs: Arguments forwarded into Home Manager modules.
      inputs: Canonically resolved flake inputs.
      modules: Resolved Home Manager module set.
      tree: Repository tree metadata used by downstream user builders.

    # Returns:
      A module fragment defining the `home-manager` configuration block.
  */
  mkModules =
    {
      host,
      specialArgs,
      inputs,
      modules,
      tree,
    }:
    {
      home-manager = {
        backupFileExtension = "BaC";
        overwriteBackup = true;
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = specialArgs // {
          lib = extend (_self: _super: { hm = inputs.home-manager.lib.hm or { }; });
        };
        users = mkUsers {
          inherit
            inputs
            modules
            host
            tree
            ;
        };
      };
    };
in
__exports.internal
// {
  inherit __doc;
  __rootAliases = __exports.external;
}
