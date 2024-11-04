{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkOption;
  inherit (lib.attrsets) mapAttrs filterAttrs hasAttr;
  inherit (lib.lists) elem;
  inherit (lib.modules) mkIf;
  inherit (config) dot;
  inherit (config.dot) users active;
  inherit (active) user host;

  userConfig =
    with user;
    mkIf (enable && (elem name (map (u: u.name) host.people))) {
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
      };

      users = {
        users = mapAttrs (
          name: u: with u; {
            inherit
              description
              isNormalUser
              hashedPassword
              shell
              ;
            uid = id;
            extraGroups = groups ++ extraGroups;
            useDefaultShell = elem shell [
              null
              config.users.defaultUserShell
            ];
          }
        ) (filterAttrs (_: u: u.enable == true) users);
      };

      home-manager = {
        backupFileExtension = "BaC";
        extraSpecialArgs = {
          inherit dot user host;
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

            programs =
              with applications;
              {
                home-manager.enable = true;
                bat = bat.export;
                btop = btop.export;
                git = git.export;
                helix = helix.export;
                # firefox = dot.applications.firefox.export;
              }
              // programs;
            # // dot.applications;

            wayland = {
              windowManager =
                let
                  mkWM =
                    wm: if hasAttr wm applications && desktop.manager == wm then applications.${wm}.export else { };
                in
                {
                  hyprland = mkWM "hyprland";
                  river = mkWM "river";
                  sway = mkWM "sway";
                };
            };
          }
        ) (filterAttrs (_: u: (u.enable == true && u.isNormalUser)) dot.users);
        verbose = true;
      };
    };
in
{
  options.dot.config.user = lib.mkOption {
    default = with userConfig; if condition == true then content else { };
  };

  config = userConfig;
}
