{
  host,
  CFG,
  lib,
  ...
}: let
  inherit (lib.attrsets) filterAttrs attrNames;
  inherit (lib.lists) elem length head;
  inherit (lib.strings) concatMapStrings;
  inherit (host) users;
  inherit (host.interface) loginManager displayProtocol desktopEnvironment;

  #~@ Filter host users with {autoLogin = true}
  autoLoginUsers = filterAttrs (_: u: (u.autoLogin or false)) users;
  autoLoginNames = attrNames autoLoginUsers;

  #~@ Resolve to the first autoLogin user if more than one
  user =
    if autoLoginNames == []
    then null
    else head autoLoginNames;

  #~@ Determine which display managers should be enabled based on host.interface.displayManager
  isLM = lm: elem loginManager [lm];

  #~@ Count enabled display managers (checking the actual config, not our intended settings)
  # Note: We check what will be enabled based on our logic, not config.services
  activeCount = lib.count (x: x) [
    (isLM "sddm")
    (isLM "gdm")
    (isLM "lightdm")
  ];
in {
  assertions = [
    {
      assertion = activeCount == 1;
      message = "Exactly one display manager must be enabled, found ${toString activeCount} enabled (displayManager = ${toString loginManager})";
    }
    {
      assertion = length autoLoginNames <= 1;
      message = ''
        Multiple users have autoLogin = true:
        ${concatMapStrings (u: " - ${u}\n") autoLoginNames}
        Please ensure at most one user has autoLogin = true.
      '';
    }
    {
      assertion = user == null || elem user (attrNames users);
      message = ''
        Invalid login user: "${toString user}"
        Available enabled users:
        ${concatMapStrings (u: " - ${u}\n") (attrNames users)}
        To resolve this, either:
        1. Choose an enabled user from the list above by setting autoLogin = true for exactly one user, e.g.:
            ${CFG}.users.craole.autoLogin = true;
        2. Enable the user in your configuration:
            ${CFG}.users.${toString user}.enable = true;
        3. Or disable automatic login by setting:
            ${CFG}.users.${toString user}.autoLogin = false;
      '';
    }
    {
      assertion = (desktopEnvironment != "gnome") || (loginManager == "gdm");
      message = ''
        Warning: You have selected the GNOME desktop environment but are using a display manager other than GDM (${toString loginManager}).
        GNOME is designed to work best with GDM, and using another display manager may cause issues with session and lock screen integration.
        Consider switching to GDM for the best GNOME experience.
      '';
    }
  ];

  services = {
    displayManager = {
      autoLogin = {
        enable = user != null;
        inherit user;
      };
      sddm = {
        enable = isLM "sddm";
        wayland.enable = elem displayProtocol ["wayland"];
      };
      gdm = {
        enable = isLM "gdm";
        wayland = elem displayProtocol ["wayland"];
      };
    };

    xserver.displayManager.lightdm = {
      enable =
        isLM "lightdm"
        || elem desktopEnvironment [
          "mate"
          "xfce"
        ];
    };
  };
}
