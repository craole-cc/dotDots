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
  mod = "shellAliases";
  cfg = DOTS.${base}.${mod};
in
{
  options.DOTS.${base}.${mod} = {
    NixOSC = mkOption {
      description = "The {{base}} {{mod}}at the system level";
      default = mkIf (nixos.config != null) (
        mkForce "sudo nixos-rebuild switch --upgrade-all --file ${nixos.config}"
      );
    };
    NixOSF = mkOption {
      description = "The {{base}} {{mod}}at the system level";
      default = mkIf (nixos.flake != null) (mkForce "sudo nixos-rebuild switch --flake ${nixos.flake}");
    };
    # Config = mkIf (nixos.config != null) (
    #   mkForce "sudo nixos-rebuild switch --upgrade-all $NIXOS_CONFIG"
    # );
  };
  # type = attrsOf attrs;

  config.${base}.${mod} = {
    inherit (cfg) NixOSC NixOSF;
  };
}
