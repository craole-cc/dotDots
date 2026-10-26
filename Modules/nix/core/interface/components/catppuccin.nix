{
  host,
  lix,
  ...
}: let
  style = lix.modules.home.style.mkStyle {inherit host;};
  inherit (style) accent catppuccin flavor;
  enable = catppuccin;
in {
  catppuccin = {
    inherit accent enable flavor;
    autoEnable = enable;
    cache = {inherit enable;};
  };
}
