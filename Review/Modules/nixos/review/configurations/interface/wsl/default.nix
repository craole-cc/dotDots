{
  lib,
  pkgs,
  # inputs,
  ...
}:
let
  inherit (lib.modules) mkForce;
in

{
  # imports = [ inputs.nixos-wsl.nixosModules.wsl ];
  config = {
    modules.device.type = "wsl";
    environment = {
      variables.BROWSER = mkForce "wsl-open";
      systemPackages = [ pkgs.wsl-open ];
    };

    services.smartd.enable = mkForce false;
    services.xserver.enable = mkForce false;
    networking.tcpcrypt.enable = mkForce false;
    services.resolved.enable = mkForce false;
    security.apparmor.enable = mkForce false;

    wsl = {
      enable = true;
      # defaultUser = config.garden.system.mainUser;
      startMenuLaunchers = true;
      interop = {
        includePath = false;
        register = true;
      };
    };
  };
}
