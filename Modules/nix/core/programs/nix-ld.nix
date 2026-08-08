{
  config,
  host,
  lib,
  pkgs,
  top,
  ...
}: let
  cfg = config.${top}.inputs.programs.nix-ld;
in {
  options.${top}.inputs.programs.nix-ld.enable = lib.mkOption {
    description = "Enable nix-ld for prebuilt dynamically linked development tools";
    default = host.capabilities.development;
    type = lib.types.bool;
  };

  config = lib.mkIf cfg.enable {
    programs.nix-ld.enable = cfg.enable;
    environment.systemPackages = [pkgs.nix-ld];
  };
}
