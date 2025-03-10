{...}: {
  # _module.args={
  config = {
    # home-manager = {
    #   backupFileExtension = "BaC";
    #   extraSpecialArgs = specialArgs;
    #   sharedModules = modules.home;
    #   useUserPackages = true;
    #   useGlobalPkgs = true;
    #   users = mapAttrs (
    #     name: user:
    #     { config, osConfig, ... }:
    #     {
    #       home = { inherit (osConfig.system) stateVersion; };
    #       wayland.windowManager.hyprland = {
    #         enable = user.desktop.manager or null == "hyprland";
    #       };
    #     }
    #   ) enabledUsers;
    #   verbose = true;
    # };

    # programs.hyprland.enable = any (user: user.desktop.manager or null == "hyprland") (
    #   attrValues enabledUsers
    # );

    # users.users = mapAttrs (
    #   name: user: with user; {
    #     inherit
    #       description
    #       isNormalUser
    #       hashedPassword
    #       ;
    #     uid = id;
    #   }
    # ) enabledUsers;
  };
}
