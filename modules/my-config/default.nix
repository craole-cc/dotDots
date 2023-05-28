{ config, lib, pkgs, ... }:
let inherit (lib) types mkIf mkDefault mkOption;
in {
  options.my-config = {
    template.desktop.gnome.enable = mkOption {
      description = "Enable my customized GNOME desktop";
      type = types.bool;
      default = false;
    };
  };

  # if my-config.template.desktop.gnome.enable is set to true
  # set the following options
  config = mkIf config.my-config.template.desktop.gnome.enable {
    services.xserver = {
      enable = true;
      desktopManager.gnome.enable = true;
      displayManager.gdm.enable = true;
    };

    # GNOME must be used with a non-root user,
    # add a non-root user
    users.users.alice = {
      # Generate hashed password with "mkpasswd -m sha-512" command,
      # "!" disables login.
      # "mkpasswd" without "-m sha-512" will not work
      initialHashedPassword = "$6$71PqhIwevs3kV.YY$A1Emwzzc0MvoquonTi7XoPxij2C.bPHaA.n0n4I0Djcd6II.22RlnKoylq6B.gBfOJ.TaSmKrRFX1GTYQvuuT0";
      description = "Full Name";
      # Users in "wheel" group are allowed to use "doas" command
      # to obtain root permissions.
      extraGroups = [ "wheel" ];
      packages = builtins.attrValues {
        inherit (pkgs)
          vscode
          alejandra
          mucommander
          #vscode-extensions.bbenoist.nix
          #vscode-extensions.kamadorueda.alejandra
          #vscode-extensions.pkief.material-icon-theme
          #vscode-extensions.pkief.material-product-icons
          #vscode-extensions.equinusocio.vsc-material-theme
        ;
      };
      isNormalUser = true;
    };
  };
}

