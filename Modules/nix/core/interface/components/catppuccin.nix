{
  host,
  lix,
  ...
}: let
  style = lix.modules.home.style.mkStyle {inherit host;};
  inherit (style) accent catppuccin flavor;
  # enable = catppuccin;
  enable = true; # TODO: This should not have to be forced. Something is wrong upstream with hos catppuccin is defined in style.
in {
  catppuccin = {
    inherit accent enable flavor;
    autoEnable = enable;
    cache = {inherit enable;};
  };
}
