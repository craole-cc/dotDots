{
  config,
  lib,
  pkgs,
  top,
  ...
}: let
  cfg = config.${top}.programs.nix-ld;
in {
  options.${top}.programs.nix-ld.enable = lib.mkOption {
    description = "Enable nix-ld for prebuilt dynamically linked development tools";
    default = true;
    type = lib.types.bool;
  };

  config = lib.mkIf cfg.enable {
    programs.nix-ld.enable = cfg.enable;
    environment.systemPackages = [pkgs.nix-ld];
  };
}
