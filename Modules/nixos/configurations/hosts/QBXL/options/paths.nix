{
  # config,
  lib,
  ...
}:
let
  dom = "dots";
  mod = "alpha";
  # cfg = config.${dom}.${mod};

  inherit (lib.options) mkOption;
  inherit (lib.types) str either path;
in
{
  options.${dom}.${mod} = {
    dots = mkOption {
      description = "The path to the dotfiles flake";
      default = "/home/craole/.dots";
      type = either str path;
    };
  };
}
