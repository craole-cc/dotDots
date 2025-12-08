{
  _cfg,
  _lib,
  lib,
  ...
}: let
  mod = "interface";
  cfg = _cfg.${mod};

  inherit (lib.options) mkOption mkEnableOption;
  inherit
    (lib.types)
    enum
    nullOr
    submodule
    int
    str
    ;
  inherit
    (_lib.enums)
    waylandSupport
    desktopEnvironments
    displayProtocols
    bootLoaders
    loginManagers
    windowManagers
    ;
in {
  ${mod} = mkOption {
    description = "Graphical User Interface configuration for desktop environment, window manager, protocol, and display manager";
    default = {};
    type = submodule {
      options = {
        bootLoader = mkOption {
          description = "Boot Loader";
          default = "systemd-boot";
          type = enum bootLoaders.enum;
        };
        bootLoaderTimeout = mkOption {
          description = "Bootloader timeout in seconds";
          default = null;
          type = nullOr int;
        };
        desktopEnvironment = mkOption {
          description = "Desktop Environment selection (GNOME, KDE, etc.)";
          default = "gnome";
          type = enum desktopEnvironments.enum;
        };

        windowManager = mkOption {
          description = "Window Manager selection with possible none for DE only setups";
          default = "none";
          type = enum windowManagers.enum;
        };

        displayProtocol = mkOption {
          description = "Graphics protocol, Wayland or X11 (xserver)";
          default = let
            inherit (waylandSupport) validator;
            check = with cfg.interface;
              validator {name = desktopEnvironment;} || validator {name = windowManager;};
          in
            if check
            then "wayland"
            else "xserver";
          type = enum displayProtocols.enum;
        };

        loginManager = mkOption {
          description = "Login/display manager selection, e.g., gdm, sddm, lightdm";
          default = "gdm";
          type = nullOr (enum loginManagers.enum);
        };

        keyboard = mkOption {
          description = "Keyboard configuration";
          default = {};
          type = submodule {
            options = {
              modifier = mkOption {
                description = "Key used as the modifier (usually SUPER_L or ALT)";
                default = "SUPER_L";
                type = str;
              };
              swapCapsEscape = mkEnableOption "CapsLock and Escape keys swap";
            };
          };
        };
      };
    };
  };
}
