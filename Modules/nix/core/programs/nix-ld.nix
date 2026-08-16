{
  config,
  host,
  lib,
  pkgs,
  top,
  lix,
  ...
}: let
  cfg = config.${top}.resolved.programs.nix-ld;
  payload = {
    programs.nix-ld.enable = cfg.enable;
    environment.systemPackages = [pkgs.nix-ld];
  };
  inherit (lix.modules.core.staging) mkStaged;
in {
  options.${top}.resolved.programs.nix-ld.enable = lib.mkOption {
    description = "Enable nix-ld for prebuilt dynamically linked development tools";
    default = host.capabilities.development;
    type = lib.types.bool;
  };

  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = cfg.enable;
  });
}
