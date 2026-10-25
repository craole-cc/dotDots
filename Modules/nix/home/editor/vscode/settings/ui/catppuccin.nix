{
  # lix,
  context,
  mkEnable,
  mkOption,
  vscodePackage,
  pkgs,
  inputs,
  ...
}: let
  # dom = "features";
  # sub = "ui";
  mod = "catppuccin";
  # cfg = context.cfg.${dom}.${sub}.${mod};

  name = mod;
  # inherit (style) catppuccin;
  # condition = catppuccin;

  extension = "Catppuccin.catppuccin-vsc";

  # description = "Catppuccin integration";
  # enable = condition;
  extensions = [extension];

  options.${mod} = {
    enable = mkEnable {
      inherit context;
      condition = true;
    };
    package = mkOption {
      default = vscodePackage {
        inherit pkgs inputs;
        entry = extension;
      };
    };
  };
  settings = {};
in {inherit name extensions options settings;}
