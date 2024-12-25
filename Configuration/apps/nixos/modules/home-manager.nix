{ specialArgs, lib, ... }:
let
  inherit (specialArgs) modules users;
  inherit (lib.attrsets) mapAttrs;

in
{
  home-manager = {
    backupFileExtension = "BaC";
    extraSpecialArgs = specialArgs;
    sharedModules = modules.home;
    useUserPackages = true;
    useGlobalPkgs = true;
    users = mapAttrs (
      _: user:
      { osConfig, ... }:
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
