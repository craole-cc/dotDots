{
  lix,
  cfg,
  style,
  pkgs,
  inputs,
  ...
}: let
  inherit (lix.options.construction) mkOption;
  inherit (lix.types.primitives) package;
  inherit (lix.attrsets.resolution) vscodePackage;
in {
  name = "catppuccin";
  description = "Catppuccin integration";
  enable = style.catppuccin;
  extensions = [cfg.features.ui.catppuccin.package];
  options.package = mkOption {
    type = package;
    default = vscodePackage {
      inherit pkgs inputs;
      entry = "Catppuccin.catppuccin-vsc";
      default = throw "The Catppuccin VS Code extension is missing from the configured catalogues.";
    };
    description = "Catppuccin VS Code extension package, including its version.";
  };
}
