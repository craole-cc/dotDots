{
  config,
  lib,
  ...
}:
let
  dom = "dots";
  mod = "desktop";
  cfg = config.${dom}.${mod};

  inherit (config.${dom}.enums)
    desktopEnvironments
    windowManagers
    displayProtocols
    loginManagers
    waylandReadyDEs
    ;
  inherit (lib.options)
    mkOption
    mkEnableOption
    ;
  inherit (lib.lists) elem;
  inherit (lib.types)
    enum
    nullOr
    str
    ;
in
{
  options.${dom}.${mod} = {
    environment = mkOption {
      description = "Desktop Environment to use";
      default = "gnome";
      type = nullOr (enum desktopEnvironments);
    };
    manager = mkOption {
      description = "Window Manager to use";
      default = "hyprland";
      type = nullOr (enum windowManagers);
    };
    protocol = mkOption {
      description = "Desktop Protocol to use";
      default = if elem cfg.environment waylandReadyDEs then "wayland" else "xserver";
      type = enum displayProtocols;
    };
    login = {
      manager = mkOption {
        description = "Login Manager to use";
        default = "sddm";
        type = nullOr (enum loginManagers);
      };
      user = mkOption {
        description = "User to use for login";
        default = null;
        type = nullOr str;
        # type = nullOr (mkOptionType {
        #   name = "user";
        #   description =
        #     let
        #       usersAvailabe = "[ ${concatMapStringsSep ", " (u: "\"${u}\"") users} ]";
        #       firstAvailable = if users == [ ] then "no defined users" else head users;
        #     in
        #     ''
        #       defined users ${usersAvailabe}

        #       To resolve this:
        #       1. Use an available user listed above:
        #         -> dots.desktop.login.user = "${firstAvailable}"

        #       2. Enable your desired user:
        #         -> dots.users.<username>.enable = true;

        #       3. Or disable automatic login:
        #         -> dots.desktop.login.automatically = false;

        #     '';
        #   check = v: elem v users;
        #   merge = mergeEqualOption;
        #   descriptionClass = "noun";
        #   emptyValue = { };
        # });
      };
      automatically = mkEnableOption "Autologin";
    };
  };
}
