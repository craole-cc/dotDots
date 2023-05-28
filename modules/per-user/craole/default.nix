{ config, lib, pkgs, ... }: 

let inherit (lin) types mkOption mkIf;
in {
  imports = [ 
    # ./modules 
    # ./templates
   ]; 
  options.zfs-root.per-user.craole.enable = mkOption {
    description = "enable user-specific options with the desktop";
    type = types.bool;
    default = false;
  };
  config = {};
}