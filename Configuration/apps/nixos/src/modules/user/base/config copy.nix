{ config, lib, ... }:
let
  #| Internal Imports
  inherit (config.DOTS)
    Active
    # Users
    Modules
    Sources
    ;
  inherit (Active) host user;

  #| External Imports
  inherit (lib.attrsets) mapAttrs filterAttrs hasAttr;
  inherit (lib.lists) elem;
  inherit (lib.options) mkOption;

  userAttrs =
    let
      inherit (Modules) user;
      inherit (Sources.user.configuration) attrs;
    in
    mapAttrs (name: path: user name path) attrs;
  # userAttrs = mapAttrs (name: path: Modules.user name path) Sources.user.configuration.attrs;
  # hostAttrs = mapAttrs (name: path: Modules.user name path) Sources.user.configuration.attrs;

  # TODO: mkConfig for every user of every host.

  # mkConfig = 

  userConfig =
    with user;
    if (enable && (elem name (map (u: u.name) host.people))) then
      {
        console = {
          inherit (fonts.console) packages font;
          earlySetup = true;
          useXkbConfig = true;
          colors = colors.console;
        };

        i18n = {
          defaultLocale = language;
          supportedLocales = [ (language + "/UTF-8") ];
        };

        programs = {
          hyprland.enable = desktop.manager == "hyprland";
        };

        services = {
          kmscon = with fonts.console; {
            enable = true;
            autologinUser = if display.autoLogin then name else null;
            extraConfig = "font-size=${toString size}";
            extraOptions = "--term xterm-256color";
            fonts = sets;
          };

          displayManager = {
            enable = !isMinimal;
            autoLogin = {
              enable = display.autoLogin;
              user = name;
            };
            sddm = {
              enable = desktop.manager == "sddm";
              wayland.enable = desktop.server == "wayland";
            };
          };

          # tailscale = {
          #   enable = elem "remote development"host.contextAllowed;
          # }
        };

        users = {
          users = mapAttrs (
            name: u: with u; {
              inherit description isNormalUser hashedPassword;
              inherit (applications) shell;
              uid = id;
              extraGroups = groups ++ extraGroups;
              useDefaultShell = elem shell [
                null
                config.users.defaultUserShell
              ];
            }
          ) (filterAttrs (_: u: u.enable == true) Users);
        };

        home-manager = {
          backupFileExtension = "BaC";
          extraSpecialArgs = {
            inherit (config) DOTS;
            inherit user host;
          };
          useUserPackages = true;
          useGlobalPkgs = true;
          users = mapAttrs (
            name: u: with u; {

              gtk = {
                enable = true;
                font = fonts.gtk;
                iconTheme = icons.gtk;
              };

              home = {
                inherit
                  packages
                  sessionVariables
                  shellAliases
                  stateVersion
                  ;
              };

              programs = {
                home-manager = {
                  enable = true;
                  path = null;
                };
              };
              # } // applications.programs // programs;

              # wayland = {
              #   windowManager =
              #     let
              #       mkWM =
              #         wm: if hasAttr wm applications && desktop.manager == wm then applications.${wm}.export else { };
              #     in
              #     {
              #       hyprland = mkWM "hyprland";
              #       river = mkWM "river";
              #       sway = mkWM "sway";
              #     };
              # };
            }
          ) (filterAttrs (_: u: (u.enable == true && u.isNormalUser)) Users);
          verbose = true;
        };
      }
    else
      { };
in
{
  options.DOTS = {
    Users = userAttrs;

    # Hosts = userAttrs;
    Config.user = mkOption { default = userConfig; };
  };

  # config = {
  #   inherit (userConfig)
  #     console
  #     i18n
  #     programs
  #     services
  #     users
  #     home-manager
  #     ;
  # };
}
