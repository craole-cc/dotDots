{ specialArgs, lib, ... }:
let
  inherit (specialArgs) host modules users;
  inherit (lib.attrsets) mapAttrs filterAttrs;

in
{
  home-manager = {
    backupFileExtension = "BaC";
    extraSpecialArgs = specialArgs;
    sharedModules = modules.home;
    useUserPackages = true;
    useGlobalPkgs = true;
    users = mapAttrs (
      name: user:
      { config, osConfig, ... }:
      {
        home = { inherit (osConfig.system) stateVersion; };
        wayland.windowManager.hyprland = {
          enable = user.desktop.manager or null == "hyprland";
        };
      }
    ) users;
    verbose = true;
  };
}
