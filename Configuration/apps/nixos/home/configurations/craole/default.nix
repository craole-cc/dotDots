{
  craole = {
    description = "Craig 'Craole' Cole";
    id = 1551;
    isAdminUser = true;
    isNormalUser = true;
    hashedPassword = "$6$FoqL4RSvypLQSN6j$RvZp4NAkCNxz/nFUuAYWo8CAXrqqrpOL/LXCBPITCkzPTso2kJXcko8O61torGdCa5pJIq/hOv2rfSwcDbOSX1";

    desktop = {
      manager = "hyprland";
      server = "wayland";
    };

    display = {
      autoLogin = true;
      manager = "sddm";
    };

    # context = config.dot.active.host.contextAllowed;
    # shell = pkgs.nushell;
    applications = {
      git = {
        name = "Craole";
        email = "32288735+Craole@users.noreply.github.com";
      };

      bat.enable = true;
      btop.enable = true;
    };
  };
}
