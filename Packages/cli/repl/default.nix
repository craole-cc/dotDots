let
  src = ../../..;
  core = import ./core.nix {inherit src;};
  helpersModule = import ./helpers.nix {
    inherit (core) lib lix api nixosConfigurations isSystemDefaultUser;
    inherit src;
  };
  helpers = helpersModule.helpers;
  configSections = import ./configSections.nix {
    inherit (core) lib host;
    inherit helpers;
  };
  apiComparison = import ./api.nix {
    inherit (core) lib api host;
    inherit (configSections) users;
  };
in {
  inherit (core) lix api lib flake pkgs system host;
  inherit builtins;
  inherit helpers;
  inherit (configSections) users aliases packages programs services variables;
  inherit (apiComparison) hostApi userApi apiComparison compareApiAttribute;
  inherit (core) nixosConfigurations;
  inherit (core.host) config options;
  inherit (core.host._module) specialArgs;
  inherit (core.flake) inputs;
}
