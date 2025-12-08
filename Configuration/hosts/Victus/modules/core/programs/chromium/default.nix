{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.strings) toJSON;
  inherit (lib.modules) mkIf;
  inherit (lib.lists) elem;
  app = "chromium";
  cfg = config.apps.${app};
  pkg = import ./packages.nix { inherit pkgs; };
  ext = import ./extensions.nix;
  managedVariants = [
    "chromium"
    "chrome"
    "brave"
  ];
in
{
  options.apps.${app} = import ./options.nix { inherit lib pkg; };

  config = mkIf cfg.enable {
    programs.chromium = mkIf (elem cfg.variant managedVariants) {
      enable = true;
      inherit (ext) extensions;
    };

    environment = lib.mkIf (!elem cfg.variant managedVariants) {
      systemPackages = [ pkg.${cfg.variant} ];
      etc = {
        "opt/chromium/policies/managed/extensions.json" = {
          text = toJSON ext.extensions;
        };
      };
    };
  };
}
