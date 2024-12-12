{ specialArgs }:
let
  inherit (specialArgs) host modules;
in
{
  home-manager = {
    backupFileExtension = "BaC";
    extraSpecialArgs = specialArgs;
    sharedModules = modules.home;
    useUserPackages = true;
    useGlobalPkgs = true;
    # users = mapAttrs (user: {

    #   # gtk = {
    #   #   enable = true;
    #   #   font = fonts.gtk;
    #   #   iconTheme = icons.gtk;
    #   # };

    #   home = {
    #     # inherit
    #     #   packages
    #     #   sessionVariables
    #     #   shellAliases
    #     #   stateVersion
    #     #   ;
    #   };

    #   programs =
    #     # with applications;
    #     {
    #       home-manager.enable = true;
    #       # bat = bat.export;
    #       # btop = btop.export;
    #       # git = git.export;
    #       # helix = helix.export;
    #       # firefox = dot.applications.firefox.export;
    #     } // programs;
    #   # // dot.applications;

    #   # wayland = {
    #   #   windowManager =
    #   #     let
    #   #       mkWM =
    #   #         wm: if hasAttr wm applications && desktop.manager == wm then applications.${wm}.export else { };
    #   #     in
    #   #     {
    #   #       hyprland = mkWM "hyprland";
    #   #       river = mkWM "river";
    #   #       sway = mkWM "sway";
    #   #     };
    #   # };
    # }) (filterAttrs (_: u: (u.enable == true && u.isNormalUser)) host.users);
    verbose = true;
  };
}
