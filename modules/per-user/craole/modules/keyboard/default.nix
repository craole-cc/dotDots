{
  config,
  lib,
  ...
}: let
  cfg = config.zfs-root.per-user.craole.modules.keyboard;
  inherit (lib) mkDefault mkOption types mkIf;
in {
  options.zfs-root.per-user.craole.modules.keyboard.enable = mkOption {
    default = false;
    type = types.bool;
  };
  config = mkIf cfg.enable {
    console.useXkbConfig = true;
    services.xserver = {
      layout = "craole";
      extraLayouts."craole" = {
        description = "zfs-root layout";
        languages = ["eng"];
        symbolsFile = ./symbols.txt;
      };
    };
    environment.variables = {XKB_DEFAULT_LAYOUT = "craole";};
  };
}
