{style, ...}: let
  enable = style.catppuccin;
  inherit (style) flavor accent;
in {
  catppuccin = {
    inherit accent enable flavor;
    autoEnable = enable;
    cache = {inherit enable;};
  };
}
