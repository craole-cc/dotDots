{
  config,
  lib,
  ...
}:
let
  inherit (lib.options) mkOption;
  inherit (lib.modules) mkForce mkIf;
  inherit (lib.types) attrsOf attrs;

  inherit (config) DOTS;
  inherit (DOTS.paths) nixos;

  base = "environment";
  mod = "variables";
  cfg = DOTS.${base}.${mod};
in
{
  options.DOTS.${base}.${mod} = mkOption {
    description = "The {{base}} {{mod}}at the system level";
    default = {
      NIXOS_CONFIG = mkIf (nixos.config != null) (mkForce nixos.config);
      NIXOS_FLAKE = mkIf (nixos.flake != null) (mkForce nixos.flake);
    };
    type = attrsOf attrs;
  };

  config.${base}.${mod} = cfg;
}
